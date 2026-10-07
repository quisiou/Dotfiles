/* quickshell/modules/Services/Meteo/MeteoService.qml */


pragma Singleton

import QtQuick
import Quickshell

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

    // ── Other ────────────────────────────────────────────────────
    property string timezone: ""
    property int utcOffsetSeconds: 0
    property real elevation: 0

    // ── WMO code → text ──────────────────────────────────────────
    readonly property var weatherCodes: ({
        0:  "Clear sky",
        1:  "Mainly clear",
        2:  "Partly cloudy",
        3:  "Overcast",
        45: "Fog",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        56: "Light freezing drizzle",
        57: "Dense freezing drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        66: "Light freezing rain",
        67: "Heavy freezing rain",
        71: "Slight snowfall",
        73: "Moderate snowfall",
        75: "Heavy snowfall",
        77: "Snow grains",
        80: "Slight rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers",
        85: "Slight snow showers",
        86: "Heavy snow showers",
        95: "Thunderstorm",
        96: "Thunderstorm with slight hail",
        97: "Heavy thunderstorm",
        99: "Thunderstorm with heavy hail"
    })

    function codeToText(code) {
        return weatherCodes[code] ?? "Unknown";
    }

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
            "dew_point_2m", "is_day", "precipitation", "rain", "showers", "snowfall",
            "snow_depth", "weather_code", "cloud_cover", "cloud_cover_low",
            "cloud_cover_mid", "cloud_cover_high", "pressure_msl", "surface_pressure",
            "visibility", "cape", "freezing_level_height", "vapour_pressure_deficit",
            "wind_speed_10m", "wind_speed_80m", "wind_speed_120m", "wind_speed_180m",
            "wind_direction_10m", "wind_direction_80m", "wind_direction_120m",
            "wind_direction_180m", "wind_gusts_10m",
            "temperature_80m", "temperature_120m", "temperature_180m",
            "shortwave_radiation", "direct_radiation", "direct_normal_irradiance",
            "diffuse_radiation", "evapotranspiration", "et0_fao_evapotranspiration",
            "soil_temperature_0cm", "soil_temperature_6cm", "soil_temperature_18cm",
            "soil_temperature_54cm", "soil_moisture_0_to_1cm", "soil_moisture_1_to_3cm",
            "soil_moisture_3_to_9cm", "soil_moisture_9_to_27cm", "soil_moisture_27_to_81cm"
        ];

        const hourlyVars = [
            "temperature_2m", "relative_humidity_2m", "dew_point_2m",
            "apparent_temperature", "precipitation_probability", "precipitation",
            "rain", "showers", "snowfall", "snow_depth", "weather_code",
            "pressure_msl", "surface_pressure", "cloud_cover", "cloud_cover_low",
            "cloud_cover_mid", "cloud_cover_high", "visibility",
            "evapotranspiration", "et0_fao_evapotranspiration", "vapour_pressure_deficit",
            "wind_speed_10m", "wind_speed_80m", "wind_speed_120m", "wind_speed_180m",
            "wind_direction_10m", "wind_direction_80m", "wind_direction_120m",
            "wind_direction_180m", "wind_gusts_10m",
            "temperature_80m", "temperature_120m", "temperature_180m",
            "shortwave_radiation", "direct_radiation", "direct_normal_irradiance",
            "diffuse_radiation", "uv_index", "uv_index_clear_sky", "is_day",
            "sunshine_duration", "cape", "freezing_level_height",
            "soil_temperature_0cm", "soil_temperature_6cm", "soil_temperature_18cm",
            "soil_temperature_54cm", "soil_moisture_0_to_1cm", "soil_moisture_1_to_3cm",
            "soil_moisture_3_to_9cm", "soil_moisture_9_to_27cm", "soil_moisture_27_to_81cm"
        ];

        const dailyVars = [
            "weather_code",
            "temperature_2m_max", "temperature_2m_mean", "temperature_2m_min",
            "apparent_temperature_max", "apparent_temperature_mean", "apparent_temperature_min",
            "sunrise", "sunset", "daylight_duration", "sunshine_duration",
            "moonrise", "moonset", "moon_phase",
            "uv_index_max", "uv_index_clear_sky_max",
            "precipitation_sum", "rain_sum", "showers_sum", "snowfall_sum",
            "precipitation_hours",
            "precipitation_probability_max", "precipitation_probability_mean",
            "precipitation_probability_min",
            "wind_speed_10m_max", "wind_gusts_10m_max", "wind_direction_10m_dominant",
            "shortwave_radiation_sum", "et0_fao_evapotranspiration"
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

            root.timezone = data.timezone;
            root.utcOffsetSeconds = data.utc_offset_seconds;
            root.elevation = data.elevation;

            root.lastUpdated = new Date();
            root.error = "";
            root.loaded = true;

            root.logOut()
        });
    }

    // ── Refresh every 30 minutes (and once at startup) ──────────
    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
