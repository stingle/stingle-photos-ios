//
//  STCameraVC.swift
//  Stingle
//
//  Stock-style native camera. Built in code so it can be presented as a gallery
//  tab or modally over the app-lock screen. Capture-only while locked.
//

import UIKit
import AVFoundation
import StingleRoot

final class STCameraVC: UIViewController {

    /// Called when the user dismisses a modally-presented camera (e.g. over lock).
    var onClose: (() -> Void)?

    private let viewModel = STCameraVM()

    private let previewView = STCameraPreviewView()
    private let gridOverlay = STCameraGridOverlayView()
    private let shutterButton = STCameraShutterButton()
    private let modeSelector = STCameraModeSelectorView()
    private let switchButton = UIButton(type: .system)
    private let thumbnailView = STImageView()
    private let flashButton = UIButton(type: .system)
    private let timerButton = UIButton(type: .system)
    private let gridButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private let lensSelector = STCameraLensSelectorView()
    private let zoomLabel = UILabel()
    private let recordTimeLabel = UILabel()
    private let countdownLabel = UILabel()
    private let focusIndicator = UIView()

    private var hasConfigured = false
    private var selfTimerSeconds = 0
    private var countdownWorkItem: DispatchWorkItem?
    private var lastZoomFactor: CGFloat = 1     // raw videoZoomFactor on the active device
    private var pinchBaseline: CGFloat = 1
    private var lenses: [STLens] = []
    private var zoomLabelHideWorkItem: DispatchWorkItem?
    private var swipeDismisser: STSwipeDownDismisser?

    /// Multiplier converting the raw videoZoomFactor to the user-facing "×" value
    /// (0.5 when an ultra-wide is the base lens, otherwise 1).
    private var displayZoomBase: CGFloat { self.lenses.first?.displayZoom ?? 1 }

    private var currentMode: STCameraMode = .photo

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.viewModel.delegate = self
        self.buildUI()
        self.previewView.delegate = self
        self.selfTimerSeconds = STAppSettings.current.camera.selfTimerSeconds
        self.updateTimerButton()
        // No close button when embedded as a tab; the tab bar handles navigation.
        let isEmbeddedTab = self.tabBarController != nil && self.presentingViewController == nil && self.onClose == nil
        self.closeButton.isHidden = isEmbeddedTab
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.previewView.session = self.viewModel.engine.captureSession
        self.gridOverlay.isHidden = !self.viewModel.gridEnabled
        self.prepareIfNeeded()
        self.loadLatestThumbnail()
        STApplication.shared.appLockUnlocker.locker.isAutoLockPaused = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.stop()
        self.cancelCountdown()
        STApplication.shared.appLockUnlocker.locker.isAutoLockPaused = false
    }

    private func prepareIfNeeded() {
        self.viewModel.requestAuthorization { [weak self] camera, _ in
            guard let self else { return }
            guard camera else {
                self.showPermissionAlert()
                return
            }
            self.viewModel.applySettings()
            if !self.hasConfigured {
                self.hasConfigured = true
                self.currentMode = self.viewModel.defaultMode
                self.viewModel.configure(mode: self.currentMode)
            }
            self.viewModel.start()
        }
    }

    // MARK: - UI

    private func buildUI() {
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.previewView)

        self.gridOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.gridOverlay.isUserInteractionEnabled = false
        self.gridOverlay.isHidden = true
        self.view.addSubview(self.gridOverlay)

        // Top control bar.
        let topBar = UIStackView()
        topBar.axis = .horizontal
        topBar.distribution = .equalSpacing
        topBar.alignment = .center
        topBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(topBar)

        self.configure(button: self.closeButton, systemImage: "xmark")
        self.closeButton.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
        self.configure(button: self.flashButton, systemImage: "bolt.badge.a.fill")
        self.flashButton.addTarget(self, action: #selector(self.didTapFlash), for: .touchUpInside)
        self.configure(button: self.timerButton, systemImage: "timer")
        self.timerButton.addTarget(self, action: #selector(self.didTapTimer), for: .touchUpInside)
        self.configure(button: self.gridButton, systemImage: "grid")
        self.gridButton.addTarget(self, action: #selector(self.didTapGrid), for: .touchUpInside)

        topBar.addArrangedSubview(self.closeButton)
        topBar.addArrangedSubview(self.flashButton)
        topBar.addArrangedSubview(self.timerButton)
        topBar.addArrangedSubview(self.gridButton)

        // Transient zoom readout (shown briefly during pinch).
        self.zoomLabel.text = "1×"
        self.zoomLabel.textColor = .systemYellow
        self.zoomLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        self.zoomLabel.textAlignment = .center
        self.zoomLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.zoomLabel.layer.cornerRadius = 16
        self.zoomLabel.layer.masksToBounds = true
        self.zoomLabel.alpha = 0
        self.zoomLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.zoomLabel)

        // Lens preset buttons (0.5× / 1× / 2× …).
        self.lensSelector.translatesAutoresizingMaskIntoConstraints = false
        self.lensSelector.delegate = self
        self.view.addSubview(self.lensSelector)

        // Recording time.
        self.recordTimeLabel.text = "00:00"
        self.recordTimeLabel.textColor = .white
        self.recordTimeLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        self.recordTimeLabel.textAlignment = .center
        self.recordTimeLabel.backgroundColor = .systemRed
        self.recordTimeLabel.layer.cornerRadius = 4
        self.recordTimeLabel.layer.masksToBounds = true
        self.recordTimeLabel.isHidden = true
        self.recordTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.recordTimeLabel)

        // Mode selector.
        self.modeSelector.translatesAutoresizingMaskIntoConstraints = false
        self.modeSelector.delegate = self
        self.view.addSubview(self.modeSelector)

        // Bottom controls.
        self.shutterButton.translatesAutoresizingMaskIntoConstraints = false
        self.shutterButton.addTarget(self, action: #selector(self.didTapShutter), for: .touchUpInside)
        self.view.addSubview(self.shutterButton)

        self.configure(button: self.switchButton, systemImage: "arrow.triangle.2.circlepath.camera")
        self.switchButton.addTarget(self, action: #selector(self.didTapSwitch), for: .touchUpInside)
        self.view.addSubview(self.switchButton)

        self.thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        self.thumbnailView.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        self.thumbnailView.layer.cornerRadius = 8
        self.thumbnailView.layer.borderWidth = 1
        self.thumbnailView.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        self.thumbnailView.clipsToBounds = true
        self.thumbnailView.contentMode = .scaleAspectFill
        self.thumbnailView.isUserInteractionEnabled = true
        self.thumbnailView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didTapThumbnail)))
        self.view.addSubview(self.thumbnailView)

        // Countdown.
        self.countdownLabel.textColor = .white
        self.countdownLabel.font = .systemFont(ofSize: 120, weight: .thin)
        self.countdownLabel.textAlignment = .center
        self.countdownLabel.isHidden = true
        self.countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.countdownLabel)

        // Focus indicator.
        self.focusIndicator.layer.borderColor = UIColor.systemYellow.cgColor
        self.focusIndicator.layer.borderWidth = 1.5
        self.focusIndicator.frame = CGRect(x: 0, y: 0, width: 72, height: 72)
        self.focusIndicator.isHidden = true
        self.view.addSubview(self.focusIndicator)

        let guide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            self.previewView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.previewView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.previewView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.previewView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            self.gridOverlay.topAnchor.constraint(equalTo: self.previewView.topAnchor),
            self.gridOverlay.leadingAnchor.constraint(equalTo: self.previewView.leadingAnchor),
            self.gridOverlay.trailingAnchor.constraint(equalTo: self.previewView.trailingAnchor),
            self.gridOverlay.bottomAnchor.constraint(equalTo: self.previewView.bottomAnchor),

            topBar.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            topBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 24),
            topBar.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -24),
            topBar.heightAnchor.constraint(equalToConstant: 44),

            self.recordTimeLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.recordTimeLabel.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 12),
            self.recordTimeLabel.widthAnchor.constraint(equalToConstant: 70),
            self.recordTimeLabel.heightAnchor.constraint(equalToConstant: 24),

            self.lensSelector.bottomAnchor.constraint(equalTo: self.modeSelector.topAnchor, constant: -10),
            self.lensSelector.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.lensSelector.heightAnchor.constraint(equalToConstant: 44),

            self.zoomLabel.bottomAnchor.constraint(equalTo: self.lensSelector.topAnchor, constant: -10),
            self.zoomLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.zoomLabel.widthAnchor.constraint(equalToConstant: 52),
            self.zoomLabel.heightAnchor.constraint(equalToConstant: 32),

            self.modeSelector.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.modeSelector.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.modeSelector.bottomAnchor.constraint(equalTo: self.shutterButton.topAnchor, constant: -16),
            self.modeSelector.heightAnchor.constraint(equalToConstant: 32),

            self.shutterButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.shutterButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -16),
            self.shutterButton.widthAnchor.constraint(equalToConstant: 74),
            self.shutterButton.heightAnchor.constraint(equalToConstant: 74),

            self.switchButton.centerYAnchor.constraint(equalTo: self.shutterButton.centerYAnchor),
            self.switchButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -36),
            self.switchButton.widthAnchor.constraint(equalToConstant: 48),
            self.switchButton.heightAnchor.constraint(equalToConstant: 48),

            self.thumbnailView.centerYAnchor.constraint(equalTo: self.shutterButton.centerYAnchor),
            self.thumbnailView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 36),
            self.thumbnailView.widthAnchor.constraint(equalToConstant: 48),
            self.thumbnailView.heightAnchor.constraint(equalToConstant: 48),

            self.countdownLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.countdownLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
    }

    private func configure(button: UIButton, systemImage: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: systemImage, withConfiguration: config), for: .normal)
    }

    // MARK: - Actions

    @objc private func didTapClose() {
        if let onClose = self.onClose {
            onClose()
        } else {
            self.dismiss(animated: true)
        }
    }

    @objc private func didTapShutter() {
        switch self.currentMode {
        case .photo, .portrait:
            if self.selfTimerSeconds > 0 {
                self.startCountdown(from: self.selfTimerSeconds) { [weak self] in
                    self?.flashScreen()
                    self?.viewModel.capturePhoto()
                }
            } else {
                self.flashScreen()        // instant feedback; capture finishes async
                self.viewModel.capturePhoto()
            }
        case .video, .slowmo:
            if self.viewModel.engine.isRecording {
                self.viewModel.stopRecording()
                self.setRecordingUI(active: false)
            } else {
                self.viewModel.startRecording()
                self.setRecordingUI(active: true)
            }
        case .timelapse:
            if self.viewModel.engine.isTimeLapsing {
                self.viewModel.stopTimeLapse()
                self.setRecordingUI(active: false)
            } else {
                self.viewModel.startTimeLapse()
                self.setRecordingUI(active: true)
            }
        }
    }

    private func setRecordingUI(active: Bool) {
        self.shutterButton.style = active ? .recording : (self.currentMode == .photo || self.currentMode == .portrait ? .photo : .video)
        self.recordTimeLabel.isHidden = !active
        self.recordTimeLabel.text = "00:00"
        self.modeSelector.isUserInteractionEnabled = !active
        self.switchButton.isEnabled = !active
        UIView.animate(withDuration: 0.2) {
            self.modeSelector.alpha = active ? 0.3 : 1
            self.switchButton.alpha = active ? 0.3 : 1
        }
    }

    @objc private func didTapSwitch() {
        // Lens list + default zoom are refreshed via didUpdateLenses(...).
        self.viewModel.engine.switchPosition()
    }

    @objc private func didTapFlash() {
        let next: STCameraFlashMode
        switch self.viewModel.engine.flashMode {
        case .auto: next = .on
        case .on: next = .off
        case .off: next = .auto
        }
        self.viewModel.engine.setFlash(next)
        let name: String
        switch next {
        case .auto: name = "bolt.badge.a.fill"
        case .on: name = "bolt.fill"
        case .off: name = "bolt.slash.fill"
        }
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        self.flashButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
    }

    @objc private func didTapTimer() {
        switch self.selfTimerSeconds {
        case 0: self.selfTimerSeconds = 3
        case 3: self.selfTimerSeconds = 10
        default: self.selfTimerSeconds = 0
        }
        var camera = STAppSettings.current.camera
        camera.selfTimerSeconds = self.selfTimerSeconds
        STAppSettings.current.camera = camera
        self.updateTimerButton()
    }

    private func updateTimerButton() {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let active = self.selfTimerSeconds != 0
        let name = active ? "timer.circle.fill" : "timer"
        self.timerButton.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
        self.timerButton.tintColor = active ? .systemYellow : .white
        // Show which setting we're on (off / 3s / 10s) next to the icon.
        let title = active ? " \(self.selfTimerSeconds)s" : nil
        self.timerButton.setTitle(title, for: .normal)
        self.timerButton.setTitleColor(.systemYellow, for: .normal)
        self.timerButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
    }

    @objc private func didTapGrid() {
        let enabled = self.gridOverlay.isHidden
        self.gridOverlay.isHidden = !enabled
        var camera = STAppSettings.current.camera
        camera.gridEnabled = enabled
        STAppSettings.current.camera = camera
        self.gridButton.tintColor = enabled ? .systemYellow : .white
    }

    @objc private func didTapThumbnail() {
        if self.viewModel.isAppLocked {
            // Locked: the encrypted library can't be decrypted, but we can still
            // review the photo just taken this session from its retained bytes.
            guard let data = self.viewModel.lastCaptureImageData, let image = UIImage(data: data) else { return }
            let review = STCaptureReviewVC(image: image)
            review.modalPresentationStyle = .fullScreen
            self.present(review, animated: true)
            self.swipeDismisser = STSwipeDownDismisser(viewController: review)
            return
        }
        self.openLatestInViewer()
    }

    /// Applies a raw videoZoomFactor (from pinch) and reflects it in the UI.
    private func applyZoom(_ factor: CGFloat, ramp: Bool = false) {
        let maxZoom = max(self.viewModel.capability.maxZoom, 1)
        let minZoom = max(self.viewModel.capability.minZoom, 1)
        let clamped = max(minZoom, min(factor, maxZoom))
        self.lastZoomFactor = clamped
        self.viewModel.engine.setZoom(clamped, ramp: ramp)
        let display = clamped * self.displayZoomBase
        self.showZoomLabel(display: display)
        self.lensSelector.updateSelection(forDisplayZoom: display)
    }

    private func showZoomLabel(display: CGFloat) {
        self.zoomLabel.text = String(format: "%.1f×", display)
        self.zoomLabelHideWorkItem?.cancel()
        UIView.animate(withDuration: 0.1) { self.zoomLabel.alpha = 1 }
        let work = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.3) { self?.zoomLabel.alpha = 0 }
        }
        self.zoomLabelHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    // MARK: - Last-capture thumbnail & viewer

    private func loadLatestThumbnail() {
        guard !self.viewModel.isAppLocked else { return }
        self.fetchNewestGalleryFile { [weak self] file in
            guard let self, let file, let source = STImageView.Image(file: file, isThumb: true) else { return }
            self.thumbnailView.setImage(source, placeholder: nil)
        }
    }

    private func openLatestInViewer() {
        self.fetchNewestGalleryFile { [weak self] file in
            guard let self, let file else { return }
            let viewer = STFileViewerVC.create(galery: self.gallerySorting(), predicate: nil, file: file)
            // Present standalone over the camera: closing / swiping down returns
            // here, not to the gallery. Hide the action bar so it can't overlap
            // the video seeker (the bar belongs on the gallery's tab bar).
            viewer.hidesActionBar = true
            let nav = UINavigationController(rootViewController: viewer)
            nav.modalPresentationStyle = .fullScreen
            viewer.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.down"),
                                                                      style: .plain, target: self,
                                                                      action: #selector(self.dismissPresentedViewer))
            self.present(nav, animated: true)
            self.swipeDismisser = STSwipeDownDismisser(viewController: nav)
        }
    }

    @objc private func dismissPresentedViewer() {
        self.presentedViewController?.dismiss(animated: true)
    }

    private func fetchNewestGalleryFile(_ completion: @escaping (STLibrary.GaleryFile?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let files = STApplication.shared.dataBase.galleryProvider.fetchObjects()
            let newest = files.max(by: { $0.dateCreated < $1.dateCreated })
            DispatchQueue.main.async { completion(newest) }
        }
    }

    private func gallerySorting() -> [STDataBase.DataSource<STLibrary.GaleryFile>.Sort] {
        let dateCreated = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.dateCreated), ascending: nil)
        let dateModified = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.dateModified), ascending: true)
        let file = STDataBase.DataSource<STLibrary.GaleryFile>.Sort(key: #keyPath(STCDGaleryFile.file), ascending: true)
        return [dateCreated, dateModified, file]
    }

    // MARK: - Countdown

    private func startCountdown(from seconds: Int, completion: @escaping () -> Void) {
        self.cancelCountdown()
        self.countdownLabel.isHidden = false
        var remaining = seconds

        func tick() {
            guard remaining > 0 else {
                self.countdownLabel.isHidden = true
                completion()
                return
            }
            self.countdownLabel.text = "\(remaining)"
            self.countdownLabel.alpha = 1
            UIView.animate(withDuration: 0.8) { self.countdownLabel.alpha = 0.2 }
            remaining -= 1
            let work = DispatchWorkItem { tick() }
            self.countdownWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
        }
        tick()
    }

    private func cancelCountdown() {
        self.countdownWorkItem?.cancel()
        self.countdownWorkItem = nil
        self.countdownLabel.isHidden = true
    }

    /// Instant black-flash over the preview so the shutter feels responsive even
    /// while the photo finishes processing asynchronously.
    private func flashScreen() {
        let flash = UIView(frame: self.previewView.bounds)
        flash.backgroundColor = .black
        flash.isUserInteractionEnabled = false
        self.previewView.addSubview(flash)
        UIView.animate(withDuration: 0.2, animations: { flash.alpha = 0 }) { _ in flash.removeFromSuperview() }
    }

    private func showPermissionAlert() {
        let alert = UIAlertController(title: "camera_not_authorized".localized,
                                     message: "camera_permission_message".localized,
                                     preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "settings".localized, style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel) { [weak self] _ in
            self?.didTapClose()
        })
        self.present(alert, animated: true)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

// MARK: - STCameraVMDelegate

extension STCameraVC: STCameraVMDelegate {

    func cameraVM(_ vm: STCameraVM, didUpdateCapability capability: STCameraCapability) {
        let modes = capability.availableModes
        self.modeSelector.configure(modes: modes, selected: self.currentMode)
        self.flashButton.isHidden = !capability.supportsFlash
    }

    func cameraVM(_ vm: STCameraVM, didCaptureThumbnail image: UIImage?) {
        // Show the just-captured plaintext thumbnail immediately (no library read).
        if let image { self.thumbnailView.image = image }
    }

    func cameraVM(_ vm: STCameraVM, didUpdateLenses lenses: [STLens], currentZoomFactor: CGFloat) {
        self.lenses = lenses
        self.lastZoomFactor = currentZoomFactor
        self.lensSelector.configure(lenses: lenses)   // selects the 1× lens by default
    }

    func cameraVM(_ vm: STCameraVM, didFail error: STCameraError) {
        let alert = UIAlertController(title: "error".localized, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok".localized, style: .default))
        self.present(alert, animated: true)
        self.setRecordingUI(active: false)
    }

    func cameraVM(_ vm: STCameraVM, didUpdateRecordingTime seconds: TimeInterval) {
        self.recordTimeLabel.text = self.formatTime(seconds)
    }

    func cameraVM(_ vm: STCameraVM, didChangeInterruption isInterrupted: Bool) {
        self.shutterButton.isEnabled = !isInterrupted
    }
}

// MARK: - Mode selector & preview

extension STCameraVC: STCameraModeSelectorViewDelegate {

    func modeSelector(_ view: STCameraModeSelectorView, didSelect mode: STCameraMode) {
        guard mode != self.currentMode else { return }
        self.currentMode = mode
        self.shutterButton.style = (mode == .photo || mode == .portrait) ? .photo : .video
        self.viewModel.engine.setMode(mode)
    }
}

extension STCameraVC: STCameraLensSelectorViewDelegate {

    func lensSelector(_ view: STCameraLensSelectorView, didSelect lens: STLens) {
        self.applyZoom(lens.zoomFactor, ramp: true)
    }
}

extension STCameraVC: STCameraPreviewViewDelegate {

    func previewView(_ view: STCameraPreviewView, didTapToFocusAt devicePoint: CGPoint, viewPoint: CGPoint) {
        self.viewModel.engine.focusAndExpose(atDevicePoint: devicePoint)
        self.focusIndicator.center = viewPoint
        self.focusIndicator.isHidden = false
        self.focusIndicator.alpha = 1
        self.focusIndicator.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        UIView.animate(withDuration: 0.3, animations: {
            self.focusIndicator.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.6, options: [], animations: {
                self.focusIndicator.alpha = 0
            }) { _ in self.focusIndicator.isHidden = true }
        }
    }

    func previewView(_ view: STCameraPreviewView, didPinchToZoom scale: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            self.pinchBaseline = self.lastZoomFactor
        case .changed:
            self.applyZoom(self.pinchBaseline * scale)
        default:
            break
        }
    }
}

/// Adds interactive swipe-down-to-dismiss to a modally-presented view controller
/// (the camera's last-photo viewer). Only engages on downward drags, so the
/// viewer's own horizontal paging and tap-to-toggle gestures keep working.
final class STSwipeDownDismisser: NSObject, UIGestureRecognizerDelegate {

    private weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        pan.delegate = self
        viewController.view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = self.viewController?.view else { return }
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .changed:
            // The view follows the finger and shrinks slightly, like Apple Photos.
            let dy = max(0, translation.y)
            let progress = min(dy / 400, 1)
            let scale = 1 - progress * 0.2
            view.transform = CGAffineTransform(translationX: translation.x, y: dy).scaledBy(x: scale, y: scale)
            view.alpha = 1 - progress * 0.4
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view)
            // Apple Photos has no distance threshold: dismiss unless the finger is
            // moving up at release, or the view ended up above where it started.
            let shouldDismiss = gesture.state == .ended && velocity.y >= 0 && translation.y > 0
            if shouldDismiss {
                self.viewController?.dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
                    view.transform = .identity
                    view.alpha = 1
                }
            }
        default:
            break
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = self.viewController?.view else { return false }
        let velocity = pan.velocity(in: view)
        return velocity.y > 0 && velocity.y > abs(velocity.x)   // downward drags only
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

/// Minimal full-screen review of the just-captured photo, used while the app is
/// locked (the encrypted library can't be opened). Swipe down or tap ✕ to close.
final class STCaptureReviewVC: UIViewController {

    private let image: UIImage
    private let imageView = UIImageView()

    override var prefersStatusBarHidden: Bool { true }

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black

        self.imageView.image = self.image
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.frame = self.view.bounds
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(self.imageView)

        let close = UIButton(type: .system)
        close.tintColor = .white
        close.setImage(UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)), for: .normal)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(self.didTapClose), for: .touchUpInside)
        self.view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 8),
            close.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            close.widthAnchor.constraint(equalToConstant: 44),
            close.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func didTapClose() {
        self.dismiss(animated: true)
    }
}
