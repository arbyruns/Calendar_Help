//
//  ContentView.swift
//  CalendarHelp
//
//  Created by robevans on 9/4/21.
//

import SwiftUI
//
//  SwiftUIView.swift
//  runable
//
//  Created by robevans on 8/16/21.
//

import SwiftUI
//modification of the code here https://gist.github.com/mecid/f8859ea4bdbd02cf5d440d58e936faec#gistcomment-3737649

struct ContentView: View {
    private let calendar: Calendar
    private let monthFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let weekDayFormatter: DateFormatter
    private let fullFormatter: DateFormatter
    private let yearFormatter: DateFormatter

    //Training data

    @StateObject var vm = DownloadHansonData()
    @AppStorage("weekNumber") var weekNumber = 1
    @AppStorage("totalWeeks") var totalWeeks = 18
    @AppStorage("userUnits") var userMeasurementChoice = "Miles"


    @State private var selectedDate = Self.now
    @State private var offset = CGSize.zero
    @State private var isDragging = false
    @State private var showTodayButton = false
    private static var now = Date() // Cache now

    init(calendar: Calendar) {
        self.calendar = calendar
        self.monthFormatter = DateFormatter(dateFormat: "MMMM", calendar: calendar)
        self.dayFormatter = DateFormatter(dateFormat: "d", calendar: calendar)
        self.weekDayFormatter = DateFormatter(dateFormat: "EEEEE", calendar: calendar)
        self.fullFormatter = DateFormatter(dateFormat: "MMMM dd, yyyy", calendar: calendar)
        self.yearFormatter = DateFormatter(dateFormat: "yyyy", calendar: calendar)
    }

    var body: some View {
        VStack  {
            CalendarView(
                calendar: calendar,
                date: $selectedDate,
                content: { date in
                    Button(action: { selectedDate = date }) {
                        ZStack {
                            Circle()
                                .fill(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ? Color("royalBlue")
                                        : calendar.isDateInToday(date) ? Color("CircleShadow")
                                    : .clear
                                )
                                .frame(width: 45, height: 45)
                            Circle()
//                                .strokeBorder(Color("DarkGray"), lineWidth: 2)
                                .strokeBorder(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ? Color("DarkGray")
                                        : calendar.isDateInToday(date) ? Color("CircleShadow")
                                    : .clear, lineWidth: 2
                                )
                                .frame(width: 38, height: 38)
                                .blur(radius: 0.8)
//                                Here's where I think we need to start adding data
                                Text(dayFormatter.string(from: date))

//                            Not sure what this does??
//                            Text("00")
//                                .foregroundColor(.clear)
//                                .accessibilityHidden(true)
//                                .overlay(
//                                        Text(dayFormatter.string(from: date))
//                                )
                        }

                    }
                    .buttonStyle(.plain)
                },
                trailing: { date in
                    Text(dayFormatter.string(from: date))
                        .foregroundColor(.secondary)
                },
                header: { date in
                    Text(weekDayFormatter.string(from: date))
                        .fontWeight(.thin)
                        .font(.callout)
                },
                title: { date in
                    HStack{
                    VStack(alignment: .leading) {
                            Text(monthFormatter.string(from: date))
                                .kerning(3)
                                .fontWeight(.semibold)
                                .textCase(.uppercase)
                                .font(.largeTitle)
                                .padding(.horizontal)
                            Text(yearFormatter.string(from: date))
                                .padding(.horizontal)
                                .padding(.bottom,5)
                        }
                        Spacer()
                    }
//                        Spacer()
                    .padding(.bottom, 6)
                }
            )
                .equatable()
            Divider()
                .frame(width: 345)
            Text("Today")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Selected date: \(fullFormatter.string(from: selectedDate))")
                .bold()
                .foregroundColor(.red)
            HStack{
                Text("Some data from the day selected")
                Spacer()
            }
            .padding()
            Spacer()
            if showTodayButton {
                Button(action: {
                    withAnimation {
                        let newDate = Date()
                        selectedDate = newDate
                        showTodayButton = false
                    }
                }) {
                    Text("Go To Today")
                }
                .buttonStyle(.plain)
            }
        }
        .offset(x: 0, y: offset.height)
        .opacity(2 - Double(abs(offset.height / 75)))
        .gesture(
//            https://stackoverflow.com/questions/62268937/swiftui-how-to-change-the-speed-of-drag-based-on-distance-already-dragged
            DragGesture()
                .onChanged { gesture in
//                    self.offset = gesture.translation
                    let limit: CGFloat = 200        // the less the faster resistance
                       let xOff = gesture.translation.width
                       let yOff = gesture.translation.height
                       let dist = sqrt(xOff*xOff + yOff*yOff);
                       let factor = 1 / (dist / limit + 1)
                       self.offset = CGSize(width: gesture.translation.width * factor,
                                           height: gesture.translation.height * factor)
                       self.isDragging = true
                }

                .onEnded { _ in
                    if self.offset.height < -75 {
                        self.offset = .zero
                        withAnimation {
                            guard let newDate = calendar.date(
                                byAdding: .month,
                                value: 1,
                                to: selectedDate
                            ) else {
                                return
                            }
                            selectedDate = newDate
                            showTodayButton = true
                        }
                    } else if self.offset.height > 75 {
                        self.offset = .zero
                        withAnimation {
                            guard let newDate = calendar.date(
                                byAdding: .month,
                                value: -1,
                                to: selectedDate
                            ) else {
                                return
                            }
                            selectedDate = newDate
                            showTodayButton = true
                        }
                    }
                }
        )
        .padding()
    }
}

// MARK: - Component

public struct CalendarView<Day: View, Header: View, Title: View, Trailing: View>: View {
    // Injected dependencies
    private var calendar: Calendar
    @Binding private var date: Date
    private let content: (Date) -> Day
    private let trailing: (Date) -> Trailing
    private let header: (Date) -> Header
    private let title: (Date) -> Title

    // Constants
    private let daysInWeek = 7

    public init(
        calendar: Calendar,
        date: Binding<Date>,
        @ViewBuilder content: @escaping (Date) -> Day,
        @ViewBuilder trailing: @escaping (Date) -> Trailing,
        @ViewBuilder header: @escaping (Date) -> Header,
        @ViewBuilder title: @escaping (Date) -> Title
    ) {
        self.calendar = calendar
        self._date = date
        self.content = content
        self.trailing = trailing
        self.header = header
        self.title = title
    }

    public var body: some View {
        let month = date.startOfMonth(using: calendar)
        let days = makeDays()

        return LazyVGrid(columns: Array(repeating: GridItem(), count: daysInWeek)) {
            Section(header: title(month)) {
                ForEach(days.prefix(daysInWeek), id: \.self, content: header)
                ForEach(days, id: \.self) { date in
                    if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                        ZStack {
                            content(date)
                        }
                    } else {
                        trailing(date)
                    }
                }
            }
        }
    }
}

// MARK: - Conformances

extension CalendarView: Equatable {
    public static func == (lhs: CalendarView<Day, Header, Title, Trailing>, rhs: CalendarView<Day, Header, Title, Trailing>) -> Bool {
        lhs.calendar == rhs.calendar && lhs.date == rhs.date
    }
}

// MARK: - Helpers

private extension CalendarView {
    func makeDays() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else {
            return []
        }

        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDays(for: dateInterval)
    }
}

private extension Calendar {
    func generateDates(
        for dateInterval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates = [dateInterval.start]

        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else { return }

            guard date < dateInterval.end else {
                stop = true
                return
            }

            dates.append(date)
        }

        return dates
    }

    func generateDays(for dateInterval: DateInterval) -> [Date] {
        generateDates(
            for: dateInterval,
            matching: dateComponents([.hour, .minute, .second], from: dateInterval.start)
        )
    }
}

private extension Date {
    func startOfMonth(using calendar: Calendar) -> Date {
        calendar.date(
            from: calendar.dateComponents([.year, .month], from: self)
        ) ?? self
    }
}

private extension DateFormatter {
    convenience init(dateFormat: String, calendar: Calendar) {
        self.init()
        self.dateFormat = dateFormat
        self.calendar = calendar
    }
}

// MARK: - Previews

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(calendar: Calendar(identifier: .gregorian))
    }
}
#endif
