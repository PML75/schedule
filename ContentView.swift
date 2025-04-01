import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var userRole: String? = nil
    @State private var currentUser: String? = nil
    @State private var users: [String: (password: String, role: String)] = ["manager": ("manager1!", "manager")]
    @State private var isDarkMode = false
    @State private var shifts: [Shift] = [] // Store shifts
    @State private var availability: [String: Availability] = [:] // Store employee availability keyed by name

    var body: some View {
        VStack {
            if isLoggedIn {
                TabView {
                    HomeView(userRole: userRole ?? "employee", shifts: $shifts, availability: $availability)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }

                    // Pass currentUser to CalendarView so it can highlight matching shifts.
                    CalendarView(shifts: shifts, currentUser: currentUser ?? "")
                        .tabItem {
                            Image(systemName: "calendar")
                            Text("Calendar")
                        }

                    SettingsView(isLoggedIn: $isLoggedIn, isDarkMode: $isDarkMode)
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                AuthView(isLoggedIn: $isLoggedIn, userRole: $userRole, currentUser: $currentUser, users: $users)
            }
        }
    }
}

struct Shift: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let time: String
    let position: String
    let section: String
}

struct Availability {
    var monday: String
    var tuesday: String
    var wednesday: String
    var thursday: String
    var friday: String
    var saturday: String
    var sunday: String
}

struct AuthView: View {
    @Binding var isLoggedIn: Bool
    @Binding var userRole: String?
    @Binding var currentUser: String?
    @Binding var users: [String: (password: String, role: String)]

    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            Text(isRegistering ? "Register" : "Sign In")
                .font(.largeTitle)
                .padding()

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(isRegistering ? "Register" : "Sign In") {
                if isRegistering {
                    registerUser()
                } else {
                    authenticateUser()
                }
            }
            .padding()

            Button(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Register") {
                isRegistering.toggle()
            }
            .padding()
        }
        .padding()
    }

    func authenticateUser() {
        if let user = users[email.lowercased()], user.password == password {
            userRole = user.role
            isLoggedIn = true
            // Save the logged-in username.
            currentUser = email.lowercased()
        } else {
            errorMessage = "Invalid credentials. Try again."
        }
    }

    func registerUser() {
        if email.isEmpty || password.isEmpty {
            errorMessage = "Email and password cannot be empty."
            return
        }
        if users[email.lowercased()] != nil {
            errorMessage = "User already exists."
            return
        }
        users[email.lowercased()] = (password, "employee")
        errorMessage = "Registered successfully! Please sign in."
        isRegistering = false
    }
}

struct HomeView: View {
    var userRole: String
    @Binding var shifts: [Shift]
    @Binding var availability: [String: Availability]
    @State private var showShiftCreator = false
    @State private var showAvailabilityForm = false

    var body: some View {
        VStack {
            Text("Welcome, \(userRole == "manager" ? "Manager" : "Employee")!")
                .font(.largeTitle)
                .padding()

            if userRole == "manager" {
                Button("Create Shift") {
                    showShiftCreator = true
                }
                .padding()
                .sheet(isPresented: $showShiftCreator) {
                    ShiftCreator(shifts: $shifts)
                }

                List(availability.keys.sorted(), id: \.self) { name in
                    VStack(alignment: .leading) {
                        Text("\(name)'s Availability")
                            .font(.headline)
                        if let avail = availability[name] {
                            Text("Mon: \(avail.monday), Tue: \(avail.tuesday), Wed: \(avail.wednesday)")
                            Text("Thu: \(avail.thursday), Fri: \(avail.friday), Sat: \(avail.saturday), Sun: \(avail.sunday)")
                        }
                    }
                }
                .padding()
            } else {
                Button("Create Availability") {
                    showAvailabilityForm = true
                }
                .padding()
                .sheet(isPresented: $showAvailabilityForm) {
                    AvailabilityForm(availability: $availability)
                }
            }
        }
    }
}

struct AvailabilityForm: View {
    @Binding var availability: [String: Availability]
    @Environment(\.presentationMode) var presentationMode

    @State private var employeeName = ""
    @State private var monday = ""
    @State private var tuesday = ""
    @State private var wednesday = ""
    @State private var thursday = ""
    @State private var friday = ""
    @State private var saturday = ""
    @State private var sunday = ""

    var body: some View {
        ScrollView {
            VStack {
                TextField("Employee Name", text: $employeeName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Group {
                    TextField("Monday", text: $monday)
                    TextField("Tuesday", text: $tuesday)
                    TextField("Wednesday", text: $wednesday)
                    TextField("Thursday", text: $thursday)
                    TextField("Friday", text: $friday)
                    TextField("Saturday", text: $saturday)
                    TextField("Sunday", text: $sunday)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                Button("Submit Availability") {
                    let newAvailability = Availability(monday: monday, tuesday: tuesday, wednesday: wednesday, thursday: thursday, friday: friday, saturday: saturday, sunday: sunday)
                    availability[employeeName] = newAvailability
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
        }
        .padding()
    }
}

struct ShiftCreator: View {
    @Binding var shifts: [Shift]
    @State private var name = ""
    @State private var date = Date()
    @State private var time = ""
    @State private var position = ""
    @State private var section = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            DatePicker("Date", selection: $date, displayedComponents: .date)
                .padding()

            TextField("Time", text: $time)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Position", text: $position)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Section", text: $section)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Add Shift") {
                let newShift = Shift(name: name, date: date, time: time, position: position, section: section)
                shifts.append(newShift)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}

// CalendarView now accepts a currentUser parameter to highlight matching shifts.
struct CalendarView: View {
    var shifts: [Shift]
    var currentUser: String
    private let calendar = Calendar.current
    @State private var expandedDay: Date? = nil

    var body: some View {
        // Horizontal scroll view for week days as square tiles
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek())!
                    DayShiftSquare(
                        day: day,
                        shifts: shiftsForDay(day),
                        isExpanded: expandedDay != nil && calendar.isDate(expandedDay!, inSameDayAs: day),
                        currentUser: currentUser
                    )
                    .onTapGesture {
                        if let expanded = expandedDay, calendar.isDate(expanded, inSameDayAs: day) {
                            expandedDay = nil
                        } else {
                            expandedDay = day
                        }
                    }
                }
            }
            .padding()
        }
    }

    // Returns the start of the current week (assuming week starts on Sunday)
    func startOfWeek() -> Date {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let start = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        return calendar.startOfDay(for: start)
    }

    // Filters shifts for a given day.
    func shiftsForDay(_ day: Date) -> [Shift] {
        shifts.filter { calendar.isDate($0.date, inSameDayAs: day) }
    }
}

struct DayShiftSquare: View {
    let day: Date
    let shifts: [Shift]
    let isExpanded: Bool
    let currentUser: String
    private let calendar = Calendar.current

    var body: some View {
        VStack {
            Text(dayFormatted())
                .font(.headline)
                .padding(.bottom, 4)

            if isExpanded {
                Divider()
                if shifts.isEmpty {
                    Text("No Shifts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(shifts) { shift in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(shift.time)
                                    .font(.subheadline)
                                HStack {
                                    // Highlight the shift name if it matches the current user.
                                    if shift.name.lowercased() == currentUser.lowercased() {
                                        Text(shift.name)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                    } else {
                                        Text(shift.name)
                                            .font(.caption)
                                    }
                                    Text("• \(shift.position) • \(shift.section)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
            } else {
                if shifts.isEmpty {
                    Text("No Shifts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(shifts.count) Shift\(shifts.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: isExpanded ? 200 : 100, height: isExpanded ? 200 : 100)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .animation(.easeInOut, value: isExpanded)
    }

    func dayFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        return formatter.string(from: day)
    }
}

struct SettingsView: View {
    @Binding var isLoggedIn: Bool
    @Binding var isDarkMode: Bool

    var body: some View {
        VStack {
            Toggle("Dark Mode", isOn: $isDarkMode)
                .padding()

            Button("Sign Out") {
                isLoggedIn = false
            }
            .padding()
        }
        .padding()
    }
}
