using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.Time.Gregorian;
using Toybox.Attention;

class ForecastLineView extends Ui.View {
    var _screenSize = new[2];
    var fahrenheit;
    var degreeHeight;
    var midScreen;
    var spacing;
    var data;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        _screenSize[0] = dc.getWidth();
        _screenSize[1] = dc.getHeight();
        degreeHeight = -_screenSize[1] / 50;
        midScreen = _screenSize[1] / 2;
        fahrenheit = (System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE);
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        drawBackground(dc);
        data = dataForDisplay();
        if ((data instanceof Toybox.Lang.Array) && (data.size() > 0)) {
            display(dc);
        } else {
            drawEmpty(dc);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    function updateModel() {
        Ui.requestUpdate();
    }

    function dataForDisplay() {
        var now = Time.now().value();
        var modulus = now % 3600;
        var hour = now - modulus;
        var start = 0;
        var hourly = App.getApp().getProperty(ForecastLine.HOURLY);
        for(var i = 0; i < hourly.size(); i++) {
            if (hourly[i].indexOf(hour) != -1) {
                start = i;
                break;
            }
        }
        return hourly.slice(start, start+9);
    }

    function display(dc) {
        spacing = (_screenSize[0]) / (data.size() - 1).toFloat();
        drawVerticalLines(dc, data.size());
        drawHours(dc);
        drawTemperatureLines(dc);
        drawIcons(dc);
        drawBottom(dc);

        var currently =  App.getApp().getProperty(ForecastLine.CURRENTLY);
        if (currently == null) {
            drawRefreshing(dc);
        } else {
            drawCurrent(dc, currently);
            Attention.backlight(true);
        }
    }

    function drawBackground(dc) {
        dc.clear();
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, _screenSize[0], _screenSize[1]);
    }

    function drawEmpty(dc) {
        var coordinates = App.getApp().getProperty(ForecastLine.COORDINATES);
        var error = App.getApp().getProperty(ForecastLine.ERROR);
        var text;
        if (coordinates == null) {
            text = "Waiting for location";
        } else if (error != null) {
            text = "Something is not right. Error" + error;
        } else {
            text = "Waiting for data";
        }
        new Ui.Text({:text => text, :color => Gfx.COLOR_LT_GRAY, :font => Gfx.FONT_XTINY, :justification => Gfx.TEXT_JUSTIFY_CENTER, :locX => _screenSize[0] / 2, :locY => midScreen}).draw(dc);
    }

    function drawVerticalLines(dc, size) {
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var x;
        for(var i = 0; i < size; i++) {
            x = i * spacing + (spacing/2);
            dc.drawLine(x, 0, x, _screenSize[1]);
        }
    }

    function drawHours(dc) {
        var x;
        var hour;
        var value;
        for(var i = 0; i < data.size(); i++) {
            x = i * spacing;
            hour = Gregorian.info(new Time.Moment(data[i][ForecastLine.TIME]), Time.FORMAT_SHORT).hour;
            if (!System.getDeviceSettings().is24Hour && hour > 12) { hour -= 12; }
            value = hour.format("%02d");
            new Ui.Text({:text => value, :color => Gfx.COLOR_LT_GRAY, :font => Gfx.FONT_XTINY, :justification => Gfx.TEXT_JUSTIFY_CENTER, :locX => x, :locY => _screenSize[1] / 5}).draw(dc);
        }
    }

    function drawTemperatureLines(dc) {
        var temperature;
        var x;
        var y;
        var previous_x = null;
        var previous_y = null;
        var precipitation = ["snow", "rain", "sleet"];
        dc.setPenWidth(3);
        for(var i = 0; i < data.size(); i++) {
            temperature = data[i][ForecastLine.TEMPERATURE];
            x = i * spacing;
            y = midScreen + ((temperature - data[0][ForecastLine.TEMPERATURE]) * degreeHeight);

            if(previous_x != null) {
                if (precipitation.indexOf(data[i][ForecastLine.ICON]) == -1) {
                    dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
                }
                dc.drawLine(previous_x, previous_y, x, y);
            }

            previous_x = x;
            previous_y = y;
        }
    }

    function drawIcons(dc) {
        var x;
        var y;
        for(var i = 1; i < data.size(); i = i + 2) {
            x = i * spacing;
            y = midScreen + ((data[i][ForecastLine.TEMPERATURE] - data[0][ForecastLine.TEMPERATURE]) * degreeHeight);

            drawIcon(dc, x - 10, y - 25, data[i][ForecastLine.ICON]);
            drawTemperature(dc, x, y, data[i][ForecastLine.TEMPERATURE]);
        }
    }

     function drawBottom(dc) {
        var divider = _screenSize[1]/5*4;
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillRectangle(0, divider, _screenSize[0], _screenSize[1]);
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(0, divider, _screenSize[0], divider);
    }

    function drawCurrent(dc, currently) {
        var x = _screenSize[0] / 2;
        var y = _screenSize[1]/5*4;
        drawIcon(dc, x - 10, y + 2, currently[ForecastLine.ICON]);
        drawTemperature(dc, x, y + 20, currently[ForecastLine.TEMPERATURE]);
    }

    function drawRefreshing(dc) {
        var x = _screenSize[0] / 2;
        var y = _screenSize[1]/5*4 + 5;
        new Ui.Text({:text => "Refreshing", :color => Gfx.COLOR_LT_GRAY, :font => Gfx.FONT_XTINY, :justification => Gfx.TEXT_JUSTIFY_CENTER, :locX => x, :locY => y}).draw(dc);
    }

    function drawIcon(dc, x, y, symbol) {
        var icon = getIcon(symbol);
        icon.setLocation(x, y);
        icon.draw(dc);
    }

    function drawTemperature(dc, x, y, temperature) {
        var value;
        if (fahrenheit) {
            value = temperature * 9 / 5 + 32;
        } else {
            value = temperature;
        }

        new Ui.Text({:text => Math.round(value).format("%i"), :color => Gfx.COLOR_BLACK, :font => Gfx.FONT_TINY, :justification => Gfx.TEXT_JUSTIFY_CENTER, :locX => x, :locY => y}).draw(dc);
    }

    var iconIds = {
        "clear-day" => Rez.Drawables.ClearDay,
        "clear-night" => Rez.Drawables.ClearNight,
        "rain" => Rez.Drawables.Rain,
        "snow" => Rez.Drawables.Snow,
        "sleet" => Rez.Drawables.Sleet,
        "wind" => Rez.Drawables.Wind,
        "fog" => Rez.Drawables.Fog,
        "cloudy" => Rez.Drawables.Cloudy,
        "partly-cloudy-day" => Rez.Drawables.PartlyCloudyDay,
        "partly-cloudy-night" => Rez.Drawables.PartlyCloudyNight
    };

    function getIcon(name) {
        return new Ui.Bitmap({:rezId=>iconIds[name]});
    }
}
