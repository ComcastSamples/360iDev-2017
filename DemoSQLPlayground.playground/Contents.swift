import Cocoa
import DemoSQL
// To use this framework, run:
// brew update && brew install plplot
import DemoPlot

// Utilities
let formatter = DateFormatter()
formatter.dateStyle = .medium
formatter.timeZone = TimeZone(secondsFromGMT: 0)!

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!

////////////////////////////////////////////////////////////////////////

// Open a database of weather measurements at DIA
let databaseURL = Bundle.main.url(forResource: "dia_measurements", withExtension: "sqlite")!
let database = try! Database(databaseURL: databaseURL)

// Show the earliest and latest date in the data set.
do {
    let statement = try database.prepare("SELECT MIN(date), MAX(date) FROM weather_measurements")
    
    let (min, max) = statement.map { cursor in (cursor[0] as Date?, cursor[1] as Date?) }.first!
    
    formatter.string(from: min!)
    formatter.string(from: max!)
}

// Show the data types available in the data set.
do {
    try database.exec("SELECT DISTINCT data_type FROM weather_measurements") { row in
        print(row.first!.value)
        return true
    }
}

// Plot the daily high between two dates.
do {
    let startDate = calendar.date(from: DateComponents(year: 2016, month: 1,  day:  1))!
    let endDate   = calendar.date(from: DateComponents(year: 2016, month: 12, day: 31))!
    
    let query = try database.prepare("SELECT date, value FROM weather_measurements WHERE date BETWEEN ? AND ? AND data_type = 'TMAX'")
    
    query.bind(startDate, endDate)
    
    let results: [(Date, Double)] = query.map { cursor in
        let celsius = Measurement(value: cursor[1], unit: UnitTemperature.celsius)
        let fahrenheit = celsius.converted(to: UnitTemperature.fahrenheit)
        
        return (cursor[0]!, fahrenheit.value)
    }
    
    drawHistogram(desiredSize: CGSize(width: 1000, height: 1000),
                  measurements: results,
                  xAxisLabel: "Temperature (f)",
                  yAxisLabel: "Number of days",
                  graphTitle: "Daily high in 2016")
}
