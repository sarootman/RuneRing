import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class RuneRingApp extends Application.AppBase {

    private var _view as RuneRingView?;

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new RuneRingView();
        _view = view;
        return [view, new RuneRingDelegate(view)];
    }

    // The user changed a setting in Garmin Connect
    function onSettingsChanged() as Void {
        if (_view != null) {
            (_view as RuneRingView).loadSettings();
        }
        WatchUi.requestUpdate();
    }
}
