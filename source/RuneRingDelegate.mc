import Toybox.Complications;
import Toybox.Lang;
import Toybox.WatchUi;

// Taps on a metric open the matching native Garmin screen
class RuneRingDelegate extends WatchUi.WatchFaceDelegate {

    private var _view as RuneRingView;

    function initialize(view as RuneRingView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    function onPress(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (!(Toybox has :Complications)) {
            return false;
        }
        var xy = clickEvent.getCoordinates();
        var type = _view.complicationAt(xy[0], xy[1]);
        if (type == null) {
            return false;
        }
        try {
            Complications.exitTo(new Complications.Id(type));
            return true;
        } catch (e) {
            return false;
        }
    }
}
