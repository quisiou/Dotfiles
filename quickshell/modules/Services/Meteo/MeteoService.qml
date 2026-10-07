/* quickshell/modules/Services/Meteo/MeteoService.qml */


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Location (auto-detected from IP) ─────────────────────────
    property real latitude: 0
    property real longitude: 0
    property string city: ""
    property string country: ""
    property bool hasLocation: false

    // ── Raw API sections (columnar, as returned by Open-Meteo) ──
    property var current: ({})   // current.temperature_2m, ...
    property var hourly: ({})    // hourly.temperature_2m[i], hourly.time[i], ...
    property var daily: ({})     // daily.temperature_2m_max[i], daily.sunrise[i], ...
    property var units: ({})     // units.current.*, units.hourly.*, units.daily.*
    property int hourIndex: 0    // index of the current hour in hourly arrays

    // ── Convenience shortcuts ────────────────────────────────────
    property real temperature: 0
    property real feelsLike: 0
    property int humidity: 0
    property real windSpeed: 0
    property int weatherCode: -1
    property bool isDay: true
    readonly property string description: codeToText(weatherCode)

    // ── Status ───────────────────────────────────────────────────
    property bool loaded: false
    property string error: ""
    property date lastUpdated

    // ── Log out the stats ────────────────────────────────────────
    function logOut() {
        if (!loaded) {
            console.log("[Weather] not loaded yet. error: " + (error || "none"));
            return;
        }

        const W = 52;
        const bar = "─".repeat(W);
        const pad = (s, n) => (String(s) + " ".repeat(n)).slice(0, n);
        const val = v => (v === null || v === undefined) ? "n/a" : v;
        const title = t => "\n┌" + bar + "\n│ " + t + "\n└" + bar + "\n";

        // Print every key of an object as "name ....... value unit"
        const dump = (obj, unitObj, index) => {
            let s = "";
            for (const k of Object.keys(obj)) {
                if (k === "time" || k === "interval") continue;
                const v = index === undefined ? obj[k] : obj[k][index];
                const u = unitObj && unitObj[k] && unitObj[k] !== "iso8601" ? " " + unitObj[k] : "";
                s += "  " + pad(k, 30) + val(v) + u + "\n";
            }
            return s;
        };

        let out = "\n" + "═".repeat(W + 1) + "\n  WEATHER  ·  " + city + ", " + country
            + "\n  " + latitude.toFixed(4) + ", " + longitude.toFixed(4)
            + "  ·  updated " + lastUpdated.toLocaleTimeString()
            + "\n" + "═".repeat(W + 1) + "\n";

        // Current
        out += title("NOW  (" + current.time + ")  " + description);
        out += dump(current, units.current);

        // Today (daily index 0)
        out += title("TODAY  (" + daily.time[0] + ")");
        out += dump(daily, units.daily, 0);

        // Next 6 hours
        out += title("NEXT 6 HOURS");
        out += "  " + pad("time", 8) + pad("temp", 9) + pad("rain%", 8)
            + pad("precip", 9) + pad("wind", 9) + "code\n";
        for (let n = 0; n < 6; n++) {
            const i = hourIndex + n;
            if (i >= hourly.time.length) break;
            out += "  " + pad(hourly.time[i].slice(11), 8)
                + pad(val(hourly.temperature_2m[i]) + "°", 9)
                + pad(val(hourly.precipitation_probability[i]) + "%", 8)
                + pad(val(hourly.precipitation[i]) + "mm", 9)
                + pad(val(hourly.wind_speed_10m[i]), 9)
                + codeToText(hourly.weather_code[i]) + "\n";
        }

        // 7-day overview
        out += title("7-DAY OUTLOOK");
        out += "  " + pad("date", 12) + pad("max", 8) + pad("min", 8)
            + pad("precip", 10) + pad("uv", 6) + "sky\n";
        for (let d = 0; d < daily.time.length; d++) {
            out += "  " + pad(daily.time[d], 12)
                + pad(val(daily.temperature_2m_max[d]) + "°", 8)
                + pad(val(daily.temperature_2m_min[d]) + "°", 8)
                + pad(val(daily.precipitation_sum[d]) + "mm", 10)
                + pad(val(daily.uv_index_max[d]), 6)
                + codeToText(daily.weather_code[d]) + "\n";
        }

        // Hourly arrays sanity check
        out += title("RAW SIZES");
        out += "  hourly points: " + hourly.time.length
            + "   daily points: " + daily.time.length
            + "   hourIndex: " + hourIndex + "\n";

        console.log(out);
    }

    // ── HTTP helper ──────────────────────────────────────────────
    function get(url, onOk) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 200) {
                root.error = "HTTP " + xhr.status + " (" + url.split("?")[0] + ")";
                return;
            }
            try {
                onOk(JSON.parse(xhr.responseText));
            } catch (e) {
                root.error = "Parse error: " + e;
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    // ── Step 1: where am I? ──────────────────────────────────────
    function refresh() {
        get("https://ipwho.is/", function (loc) {
            if (loc.success === false) {
                root.error = "Geolocation failed";
                if (!root.hasLocation) return;   // otherwise reuse last known coords
            } else {
                root.latitude = loc.latitude;
                root.longitude = loc.longitude;
                root.city = loc.city;
                root.country = loc.country;
                root.hasLocation = true;
            }
            root.fetchWeather();
        });
    }

    // ── Step 2: everything Open-Meteo has, in one request ───────
    function fetchWeather() {
        const currentVars = [
            "temperature_2m", "apparent_temperature", "relative_humidity_2m",
            "is_day", "precipitation", "rain", "showers", "snowfall",
            "weather_code", "cloud_cover", "pressure_msl", "surface_pressure",
            "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m"
        ];

        const hourlyVars = [
            "temperature_2m", "relative_humidity_2m", "dew_point_2m",
            "apparent_temperature", "precipitation_probability", "precipitation",
            "rain", "showers", "snowfall", "snow_depth", "weather_code",
            "pressure_msl", "surface_pressure", "cloud_cover", "cloud_cover_low",
            "cloud_cover_mid", "cloud_cover_high", "visibility",
            "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m",
            "uv_index", "is_day", "sunshine_duration", "cape",
            "freezing_level_height", "soil_temperature_0cm", "soil_moisture_0_to_1cm"
        ];

        const dailyVars = [
            "weather_code", "temperature_2m_max", "temperature_2m_min",
            "apparent_temperature_max", "apparent_temperature_min",
            "sunrise", "sunset", "daylight_duration", "sunshine_duration",
            "uv_index_max", "precipitation_sum", "rain_sum", "showers_sum",
            "snowfall_sum", "precipitation_hours", "precipitation_probability_max",
            "wind_speed_10m_max", "wind_gusts_10m_max",
            "wind_direction_10m_dominant", "shortwave_radiation_sum",
            "et0_fao_evapotranspiration"
        ];

        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude
            + "&longitude=" + longitude
            + "&timezone=auto&forecast_days=7"
            + "&current=" + currentVars.join(",")
            + "&hourly=" + hourlyVars.join(",")
            + "&daily=" + dailyVars.join(",");

        get(url, function (data) {
            root.current = data.current;
            root.hourly = data.hourly;
            root.daily = data.daily;
            root.units = {
                current: data.current_units,
                hourly: data.hourly_units,
                daily: data.daily_units
            };

            // Index of the current hour in the hourly arrays
            const i = data.hourly.time.findIndex(t => t > data.current.time);
            root.hourIndex = i > 0 ? i - 1 : 0;

            // Shortcuts
            root.temperature = data.current.temperature_2m;
            root.feelsLike = data.current.apparent_temperature;
            root.humidity = data.current.relative_humidity_2m;
            root.windSpeed = data.current.wind_speed_10m;
            root.weatherCode = data.current.weather_code;
            root.isDay = data.current.is_day === 1;

            root.lastUpdated = new Date();
            root.error = "";
            root.loaded = true;

            root.logOut()
        });
    }

    // ── WMO code → text ──────────────────────────────────────────
    function codeToText(code) {
        if (code === 0) return "Clear sky";
        if (code <= 3) return "Partly cloudy";
        if (code <= 48) return "Fog";
        if (code <= 57) return "Drizzle";
        if (code <= 67) return "Rain";
        if (code <= 77) return "Snow";
        if (code <= 82) return "Rain showers";
        if (code <= 86) return "Snow showers";
        if (code >= 95) return "Thunderstorm";
        return "Unknown";
    }

    // ── Refresh every 30 minutes (and once at startup) ──────────
    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
