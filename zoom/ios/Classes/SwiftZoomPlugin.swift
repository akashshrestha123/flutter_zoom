import Flutter
import UIKit
import MobileRTC

public class SwiftZoomPlugin: NSObject, FlutterPlugin, FlutterStreamHandler , MobileRTCMeetingServiceDelegate {
    
    var authenticationDelegate: AuthenticationDelegate
    var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: "plugins.vurilo/zoom_channel", binaryMessenger: messenger)
        let instance = SwiftZoomPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let eventChannel = FlutterEventChannel(name: "com.vurilo/zoom_event_stream", binaryMessenger: messenger)
        eventChannel.setStreamHandler(instance)
    }
    
    override init(){
        authenticationDelegate = AuthenticationDelegate()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "init":
            self.initZoom(call: call, result: result)
            //   case "login":
            //       self.login(call: call, result: result)
        case "join":
            self.joinMeeting(call: call, result: result)
        case "start":
            self.startMeeting(call: call, result: result)
        case "meeting_status":
            self.meetingStatus(call: call, result: result)
        case "meeting_details":
            self.meetingDetails(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        switch call.method {
        case "init":
            self.initZoom(call: call, result: result)
            //   case "login":
            //       self.login(call: call, result: result)
        case "join":
            self.joinMeeting(call: call, result: result)
        case "meeting_status":
            self.meetingStatus(call: call, result: result)
        case "start":
            self.startMeeting(call: call, result: result)
        case "meeting_details":
            self.meetingDetails(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    //Initializing the Zoom SDK for iOS
    public func initZoom(call: FlutterMethodCall, result: @escaping FlutterResult)  {
        
        let pluginBundle = Bundle(for: type(of: self))
        let pluginBundlePath = pluginBundle.bundlePath
        let arguments = call.arguments as! Dictionary<String, String>
        
        let context = MobileRTCSDKInitContext()
        context.domain = arguments["domain"]!
        context.bundleResPath = pluginBundlePath
        context.appGroupId = arguments["appGroupId"]
        context.replaykitBundleIdentifier = "com.vurilo.app"
        MobileRTC.shared().initialize(context)
        
        let auth = MobileRTC.shared().getAuthService()
        auth?.delegate = self.authenticationDelegate.onAuth(result)
        if let appKey = arguments["appKey"] {
            auth?.clientKey = appKey
        }
        if let appSecret = arguments["appSecret"] {
            auth?.clientSecret = appSecret
        }
        if let jwtToken = arguments["jwtToken"]{
            auth?.jwtToken = jwtToken
        }
        
        auth?.sdkAuth()
    }
    
    //Listen to meeting status on joining and starting the meeting
    public func meetingStatus(call: FlutterMethodCall, result: FlutterResult) {
        
        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService != nil {
            let meetingState = meetingService?.getMeetingState()
            result(getStateMessage(meetingState))
        } else {
            result(["MEETING_STATUS_UNKNOWN", ""])
        }
    }
    
    //Get Meeting Details Programmatically after Starting the Meeting
    public func meetingDetails(call: FlutterMethodCall, result: FlutterResult) {
        
        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService != nil {
            let meetingPassword = MobileRTCInviteHelper.sharedInstance().rawMeetingPassword
            let meetingNumber = MobileRTCInviteHelper.sharedInstance().ongoingMeetingNumber
            
            result([meetingNumber, meetingPassword])
            
        } else {
            result(["MEETING_STATUS_UNKNOWN", "No status available"])
        }
    }
    
    //Join Meeting with passed Meeting ID and PassCode
    public func joinMeeting(call: FlutterMethodCall, result: FlutterResult) {
        
        let meetingService = MobileRTC.shared().getMeetingService()
        let meetingSettings = MobileRTC.shared().getMeetingSettings()
        
        if (meetingService != nil) {
            meetingService?.customizeMeetingTitle("Vurilo")
            
            let arguments = call.arguments as! Dictionary<String, String?>
            
            //Setting up meeting settings for zoom sdk
            meetingSettings?.disableDriveMode(parseBoolean(data: arguments["disableDrive"]!, defaultValue: false))
            meetingSettings?.disableCall(in: parseBoolean(data: arguments["disableDialIn"]!, defaultValue: true))
            meetingSettings?.setAutoConnectInternetAudio(parseBoolean(data: arguments["noDisconnectAudio"]!, defaultValue: true))
            meetingSettings?.setMuteAudioWhenJoinMeeting(parseBoolean(data: arguments["noAudio"]!, defaultValue: true))
            meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["disableShare"]!, defaultValue: false)
            meetingSettings?.meetingInviteHidden = parseBoolean(data: arguments["disableInvite"]!, defaultValue: true)
            meetingSettings?.disableCopyMeetingUrl(true);
            if  arguments["viewOptions"] != nil{
                let viewOpts = parseBoolean(data:arguments["viewOptions"]!, defaultValue: true)
                if viewOpts {
                    meetingSettings?.meetingTitleHidden = false
                    meetingSettings?.meetingPasswordHidden = true
                    meetingSettings?.meetingInviteHidden = true
                    meetingSettings?.meetingInviteUrlHidden = true
                    // meetingSettings?.meetingShareHidden = true
                    // meetingSettings?.hintHidden=true
                }
            }
            
            //Setting up Join Meeting parameter
            let joinMeetingParameters = MobileRTCMeetingJoinParam()
            
            //Setting up Custom Join Meeting parameter
            joinMeetingParameters.userName = arguments["displayName"]!!
            joinMeetingParameters.meetingNumber = arguments["meetingId"]!!
            
            let hasPassword = arguments["meetingPassword"]! != nil
            if hasPassword {
                joinMeetingParameters.password = arguments["meetingPassword"]!!
            }
            
            //Joining the meeting and storing the response
            let response = meetingService?.joinMeeting(with: joinMeetingParameters)
            
            if let response = response {
                print("Got response from join: \(response)")
            }
            result(true)
        } else {
            result(false)
        }
    }
    
    public func startMeeting(call: FlutterMethodCall, result: FlutterResult) {
        
        let meetingService = MobileRTC.shared().getMeetingService()
        let meetingSettings = MobileRTC.shared().getMeetingSettings()
        
        if meetingService != nil {
            meetingService?.customizeMeetingTitle("Vurilo")
            
            let arguments = call.arguments as! Dictionary<String, String?>
            meetingSettings?.disableDriveMode(parseBoolean(data: arguments["disableDrive"]!, defaultValue: false))
            meetingSettings?.disableCall(in: parseBoolean(data: arguments["disableDialIn"]!, defaultValue: true))
            meetingSettings?.setAutoConnectInternetAudio(parseBoolean(data: arguments["noDisconnectAudio"]!, defaultValue: true))
            meetingSettings?.setMuteAudioWhenJoinMeeting(parseBoolean(data: arguments["noAudio"]!, defaultValue: true))
            meetingSettings?.meetingShareHidden = parseBoolean(data: arguments["disableShare"]!, defaultValue: true)
            meetingSettings?.meetingInviteHidden = parseBoolean(data: arguments["disableInvite"]!, defaultValue: true)
            meetingSettings?.disableCopyMeetingUrl(true);
            if  arguments["viewOptions"] != nil{
                let viewOpts = parseBoolean(data:arguments["viewOptions"]!, defaultValue: true)
                if viewOpts {
                    meetingSettings?.meetingTitleHidden = false
                    meetingSettings?.meetingPasswordHidden = true
                    meetingSettings?.meetingInviteHidden = true
                    meetingSettings?.meetingInviteUrlHidden = true
                    // meetingSettings?.meetingShareHidden = true
                    // meetingSettings?.hintHidden = true
                }
            }
            let user: MobileRTCMeetingStartParam4WithoutLoginUser = MobileRTCMeetingStartParam4WithoutLoginUser.init()
            
            user.userType = .apiUser
            user.meetingNumber = arguments["meetingId"]!!
            user.userName = arguments["displayName"]!!
            // user.userToken = arguments["zoomToken"]!!
            user.userID = arguments["userId"]!!
            user.zak = arguments["zoomAccessToken"]!!
            // user.isAppShare = true
            let param: MobileRTCMeetingStartParam = user
            
            let response = meetingService?.startMeeting(with: param)
            
            if let response = response {
                print("Got response from start: \(response)")
            }
            result(true)
        } else {
            result(false)
        }
    }
    
    
    //Helper Function for parsing string to boolean value
    private func parseBoolean(data: String?, defaultValue: Bool) -> Bool {
        var result: Bool
        
        if let unWrappedData = data {
            result = NSString(string: unWrappedData).boolValue
        } else {
            result = defaultValue
        }
        return result
    }
    
    //Helper Function for parsing string to int value
    private func parseInt(data: String?, defaultValue: Int) -> Int {
        var result: Int
        
        if let unWrappedData = data {
            result = NSString(string: unWrappedData).integerValue
        } else {
            result = defaultValue
        }
        return result
    }
    
    
    public func onMeetingError(_ error: MobileRTCMeetError, message: String?) {
        
    }
    
    public func getMeetErrorMessage(_ errorCode: MobileRTCMeetError) -> String {
        
        let message = ""
        return message
    }
    
    public func onMeetingStateChange(_ state: MobileRTCMeetingState) {
        
        guard let eventSink = eventSink else {
            return
        }
        
        eventSink(getStateMessage(state))
    }
    
    //Listen to initializing sdk events
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        let meetingService = MobileRTC.shared().getMeetingService()
        if meetingService == nil {
            return FlutterError(code: "Zoom SDK error", message: "ZoomSDK is not initialized", details: nil)
        }
        meetingService?.delegate = self
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    //Get Meeting Status message with proper codes
    private func getStateMessage(_ state: MobileRTCMeetingState?) -> [String] {
        
        var message: [String]
        switch state {
        case  .idle:
            message = ["MEETING_STATUS_IDLE", "No meeting is running"]
            break
        case .connecting:
            message = ["MEETING_STATUS_CONNECTING", "Connect to the meeting server"]
            break
        case .inMeeting:
            message = ["MEETING_STATUS_INMEETING", "Meeting is ready and in process"]
            break
        case .webinarPromote:
            message = ["MEETING_STATUS_WEBINAR_PROMOTE", "Upgrade the attendees to panelist in webinar"]
            break
        case .webinarDePromote:
            message = ["MEETING_STATUS_WEBINAR_DEPROMOTE", "Demote the attendees from the panelist"]
            break
        case .disconnecting:
            message = ["MEETING_STATUS_DISCONNECTING", "Disconnect the meeting server, leave meeting status"]
            break;
        case .ended:
            message = ["MEETING_STATUS_ENDED", "Meeting ends"]
            break;
        case .failed:
            message = ["MEETING_STATUS_FAILED", "Failed to connect the meeting server"]
            break;
        case .reconnecting:
            message = ["MEETING_STATUS_RECONNECTING", "Reconnecting meeting server status"]
            break;
        case .waitingForHost:
            message = ["MEETING_STATUS_WAITINGFORHOST", "Waiting for the host to start the meeting"]
            break;
        case .inWaitingRoom:
            message = ["MEETING_STATUS_IN_WAITING_ROOM", "Participants who join the meeting before the start are in the waiting room"]
            break;
        default:
            message = ["MEETING_STATUS_UNKNOWN", "'(state?.rawValue ?? 9999)'"]
        }
        return message
    }
}

//Zoom SDK Authentication Listener
public class AuthenticationDelegate: NSObject, MobileRTCAuthDelegate {
    
    private var result: FlutterResult?
    
    //Zoom SDK Authentication Listener - On Auth get result
    public func onAuth(_ result: FlutterResult?) -> AuthenticationDelegate {
        self.result = result
        return self
    }
    
    //Zoom SDK Authentication Listener - On MobileRTCAuth get result
    public func onMobileRTCAuthReturn(_ returnValue: MobileRTCAuthError) {
        
        if returnValue == .success {
            self.result?([0, 0])
        } else {
            self.result?([1, 0])
        }
        
        self.result = nil
    }
    
    //Zoom SDK Authentication Listener - On onMobileRTCLoginReturn get status
    public func onMobileRTCLoginReturn(_ returnValue: Int){
        
    }
    
    //Zoom SDK Authentication Listener - On onMobileRTCLogoutReturn get message
    public func onMobileRTCLogoutReturn(_ returnValue: Int) {
        
    }
    
    //Zoom SDK Authentication Listener - On getAuthErrorMessage get message
    public func getAuthErrorMessage(_ errorCode: MobileRTCAuthError) -> String {
        
        let message = ""
        
        return message
    }
}
