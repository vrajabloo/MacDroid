//
// GamingSettings.swift
// MacDroid
//
// Stores user-facing performance preferences. Some settings are written into an
// AVD config file, while others are launch preferences the app can apply later.

import Foundation

struct GamingSettings: Codable, Equatable {
    var performanceProfile: PerformanceProfile
    var ramPreset: RAMPreset
    var cpuPreset: CPUPreset
    var resolutionPreset: ResolutionPreset
    var dpiPreset: DPIPreset
    var fpsTarget: FPSTarget
    var performanceModeEnabled: Bool
    var batterySavingEnabled: Bool
    var fullscreenEnabled: Bool
    var windowSizePreset: WindowSizePreset
    var customSDKRootPath: String?
    var launchEmulatorWhenAppOpens: Bool
    var autoLaunchLastGameAfterBoot: Bool
    var hideOfficialEmulatorToolbar: Bool
    var repairOfficialEmulatorToolbar: Bool
    var networkBoostEnabled: Bool
    var dnsPreset: DNSPreset
    var setupWizardCompleted: Bool
    var checkForUpdatesAutomatically: Bool

    static let `default` = GamingSettings(
        performanceProfile: .performance,
        ramPreset: .gb4,
        cpuPreset: .four,
        resolutionPreset: .p1080,
        dpiPreset: .dpi320,
        fpsTarget: .fps60,
        performanceModeEnabled: true,
        batterySavingEnabled: false,
        fullscreenEnabled: false,
        windowSizePreset: .large,
        customSDKRootPath: nil,
        launchEmulatorWhenAppOpens: true,
        autoLaunchLastGameAfterBoot: false,
        hideOfficialEmulatorToolbar: false,
        repairOfficialEmulatorToolbar: true,
        networkBoostEnabled: true,
        dnsPreset: .googleCloudflare,
        setupWizardCompleted: false,
        checkForUpdatesAutomatically: true
    )

    enum CodingKeys: String, CodingKey {
        case performanceProfile
        case ramPreset
        case cpuPreset
        case resolutionPreset
        case dpiPreset
        case fpsTarget
        case performanceModeEnabled
        case batterySavingEnabled
        case fullscreenEnabled
        case windowSizePreset
        case customSDKRootPath
        case launchEmulatorWhenAppOpens
        case autoLaunchLastGameAfterBoot
        case hideOfficialEmulatorToolbar
        case repairOfficialEmulatorToolbar
        case networkBoostEnabled
        case dnsPreset
        case setupWizardCompleted
        case checkForUpdatesAutomatically
    }

    init(
        performanceProfile: PerformanceProfile,
        ramPreset: RAMPreset,
        cpuPreset: CPUPreset,
        resolutionPreset: ResolutionPreset,
        dpiPreset: DPIPreset,
        fpsTarget: FPSTarget,
        performanceModeEnabled: Bool,
        batterySavingEnabled: Bool,
        fullscreenEnabled: Bool,
        windowSizePreset: WindowSizePreset,
        customSDKRootPath: String?,
        launchEmulatorWhenAppOpens: Bool,
        autoLaunchLastGameAfterBoot: Bool,
        hideOfficialEmulatorToolbar: Bool,
        repairOfficialEmulatorToolbar: Bool,
        networkBoostEnabled: Bool,
        dnsPreset: DNSPreset,
        setupWizardCompleted: Bool,
        checkForUpdatesAutomatically: Bool
    ) {
        self.performanceProfile = performanceProfile
        self.ramPreset = ramPreset
        self.cpuPreset = cpuPreset
        self.resolutionPreset = resolutionPreset
        self.dpiPreset = dpiPreset
        self.fpsTarget = fpsTarget
        self.performanceModeEnabled = performanceModeEnabled
        self.batterySavingEnabled = batterySavingEnabled
        self.fullscreenEnabled = fullscreenEnabled
        self.windowSizePreset = windowSizePreset
        self.customSDKRootPath = customSDKRootPath
        self.launchEmulatorWhenAppOpens = launchEmulatorWhenAppOpens
        self.autoLaunchLastGameAfterBoot = autoLaunchLastGameAfterBoot
        self.hideOfficialEmulatorToolbar = hideOfficialEmulatorToolbar
        self.repairOfficialEmulatorToolbar = repairOfficialEmulatorToolbar
        self.networkBoostEnabled = networkBoostEnabled
        self.dnsPreset = dnsPreset
        self.setupWizardCompleted = setupWizardCompleted
        self.checkForUpdatesAutomatically = checkForUpdatesAutomatically
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.performanceProfile = try container.decodeIfPresent(PerformanceProfile.self, forKey: .performanceProfile) ?? .performance
        self.ramPreset = try container.decodeIfPresent(RAMPreset.self, forKey: .ramPreset) ?? .gb4
        self.cpuPreset = try container.decodeIfPresent(CPUPreset.self, forKey: .cpuPreset) ?? .four
        self.resolutionPreset = try container.decodeIfPresent(ResolutionPreset.self, forKey: .resolutionPreset) ?? .p1080
        self.dpiPreset = try container.decodeIfPresent(DPIPreset.self, forKey: .dpiPreset) ?? .dpi320
        self.fpsTarget = try container.decodeIfPresent(FPSTarget.self, forKey: .fpsTarget) ?? .fps60
        self.performanceModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .performanceModeEnabled) ?? true
        self.batterySavingEnabled = try container.decodeIfPresent(Bool.self, forKey: .batterySavingEnabled) ?? false
        self.fullscreenEnabled = try container.decodeIfPresent(Bool.self, forKey: .fullscreenEnabled) ?? false
        self.windowSizePreset = try container.decodeIfPresent(WindowSizePreset.self, forKey: .windowSizePreset) ?? .large
        self.customSDKRootPath = try container.decodeIfPresent(String.self, forKey: .customSDKRootPath)
        self.launchEmulatorWhenAppOpens = try container.decodeIfPresent(Bool.self, forKey: .launchEmulatorWhenAppOpens) ?? true
        self.autoLaunchLastGameAfterBoot = try container.decodeIfPresent(Bool.self, forKey: .autoLaunchLastGameAfterBoot) ?? false
        self.hideOfficialEmulatorToolbar = try container.decodeIfPresent(Bool.self, forKey: .hideOfficialEmulatorToolbar) ?? false
        self.repairOfficialEmulatorToolbar = try container.decodeIfPresent(Bool.self, forKey: .repairOfficialEmulatorToolbar) ?? true
        self.networkBoostEnabled = try container.decodeIfPresent(Bool.self, forKey: .networkBoostEnabled) ?? true
        self.dnsPreset = try container.decodeIfPresent(DNSPreset.self, forKey: .dnsPreset) ?? .googleCloudflare
        self.setupWizardCompleted = try container.decodeIfPresent(Bool.self, forKey: .setupWizardCompleted) ?? true
        self.checkForUpdatesAutomatically = try container.decodeIfPresent(Bool.self, forKey: .checkForUpdatesAutomatically) ?? true
    }
}

enum PerformanceProfile: String, Codable, CaseIterable, Identifiable {
    case balanced = "Balanced"
    case performance = "Performance"
    case batterySaver = "Battery Saver"
    case custom = "Custom"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .balanced: return "dial.medium.fill"
        case .performance: return "bolt.fill"
        case .batterySaver: return "leaf.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var summary: String {
        switch self {
        case .balanced: return "Good speed with moderate resources."
        case .performance: return "Best gaming feel for Apple Silicon."
        case .batterySaver: return "Lower resource use for lighter games."
        case .custom: return "Manual RAM, CPU, resolution, and FPS."
        }
    }
}

enum RAMPreset: String, Codable, CaseIterable, Identifiable {
    case gb2 = "2 GB"
    case gb4 = "4 GB"
    case gb6 = "6 GB"
    case gb8 = "8 GB"

    var id: String { rawValue }

    var megabytes: Int {
        switch self {
        case .gb2: return 2048
        case .gb4: return 4096
        case .gb6: return 6144
        case .gb8: return 8192
        }
    }
}

enum CPUPreset: String, Codable, CaseIterable, Identifiable {
    case two = "2 cores"
    case four = "4 cores"
    case six = "6 cores"
    case eight = "8 cores"

    var id: String { rawValue }

    var cores: Int {
        switch self {
        case .two: return 2
        case .four: return 4
        case .six: return 6
        case .eight: return 8
        }
    }
}

enum ResolutionPreset: String, Codable, CaseIterable, Identifiable {
    case p720 = "720p"
    case p1080 = "1080p"
    case p1440 = "1440p"

    var id: String { rawValue }

    var size: (width: Int, height: Int) {
        switch self {
        case .p720: return (1280, 720)
        case .p1080: return (1920, 1080)
        case .p1440: return (2560, 1440)
        }
    }
}

enum DPIPreset: String, Codable, CaseIterable, Identifiable {
    case dpi240 = "240 DPI"
    case dpi320 = "320 DPI"
    case dpi420 = "420 DPI"
    case dpi560 = "560 DPI"

    var id: String { rawValue }

    var value: Int {
        switch self {
        case .dpi240: return 240
        case .dpi320: return 320
        case .dpi420: return 420
        case .dpi560: return 560
        }
    }
}

enum FPSTarget: String, Codable, CaseIterable, Identifiable {
    case fps30 = "30 FPS"
    case fps60 = "60 FPS"
    case fps90 = "90 FPS"
    case fps120 = "120 FPS"

    var id: String { rawValue }

    var value: Int {
        switch self {
        case .fps30: return 30
        case .fps60: return 60
        case .fps90: return 90
        case .fps120: return 120
        }
    }
}

enum WindowSizePreset: String, Codable, CaseIterable, Identifiable {
    case compact = "Compact"
    case medium = "Medium"
    case large = "Large"
    case fullscreen = "Fullscreen"

    var id: String { rawValue }
}

enum DNSPreset: String, Codable, CaseIterable, Identifiable {
    case googleCloudflare = "Google + Cloudflare"
    case google = "Google DNS"
    case cloudflare = "Cloudflare DNS"
    case quad9 = "Quad9 DNS"

    var id: String { rawValue }

    var servers: String {
        switch self {
        case .googleCloudflare: return "8.8.8.8,1.1.1.1"
        case .google: return "8.8.8.8,8.8.4.4"
        case .cloudflare: return "1.1.1.1,1.0.0.1"
        case .quad9: return "9.9.9.9,149.112.112.112"
        }
    }
}
