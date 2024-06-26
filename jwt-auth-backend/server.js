const express = require('express');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const mongoose = require('mongoose');
const moment = require('moment');
const { google } = require('googleapis');
const fs = require('fs');
const readline = require('readline');
const path = require('path');

const app = express();
app.use(bodyParser.json());
app.use(cors());

const secretKey = 'your-secret-key';

// Connect to MongoDB
mongoose.connect('mongodb+srv://Rithvik:rithvik123@sdapp1.4t2ccd9.mongodb.net/mydb?retryWrites=true&w=majority', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('Connected to MongoDB Atlas');
}).catch(err => {
  console.error('Error connecting to MongoDB', err);
});

// Google Calendar API setup
const CREDENTIALS_PATH = path.join(__dirname, 'credentials.json');
const TOKEN_PATH = path.join(__dirname, 'token.json');

const SCOPES = ['https://www.googleapis.com/auth/calendar'];

let oAuth2Client;

// Load client secrets from a local file.
fs.readFile(CREDENTIALS_PATH, (err, content) => {
  if (err) return console.error('Error loading client secret file:', err);
  authorize(JSON.parse(content));
});

function authorize(credentials) {
  const { client_secret, client_id, redirect_uris } = credentials.installed || credentials.web;
  oAuth2Client = new google.auth.OAuth2(client_id, client_secret, redirect_uris[0]);

  fs.readFile(TOKEN_PATH, (err, token) => {
    if (err) return getAccessToken(oAuth2Client);
    oAuth2Client.setCredentials(JSON.parse(token));
    console.log('Google Calendar API authenticated successfully');
  });
}

function getAccessToken(oAuth2Client) {
  const authUrl = oAuth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
  });
  console.log('Authorize this app by visiting this url:', authUrl);
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  rl.question('Enter the code from that page here: ', (code) => {
    rl.close();
    oAuth2Client.getToken(code, (err, token) => {
      if (err) return console.error('Error retrieving access token', err);
      oAuth2Client.setCredentials(token);
      fs.writeFile(TOKEN_PATH, JSON.stringify(token), (err) => {
        if (err) return console.error(err);
        console.log('Token stored to', TOKEN_PATH);
      });
    });
  });
}

async function addEventToCalendar(eventDetails) {
  const calendar = google.calendar({ version: 'v3', auth: oAuth2Client });
  const event = {
    summary: eventDetails.summary,
    description: eventDetails.description,
    start: {
      dateTime: eventDetails.start,
      timeZone: 'America/Los_Angeles',
    },
    end: {
      dateTime: eventDetails.end,
      timeZone: 'America/Los_Angeles',
    },
  };
  try {
    const response = await calendar.events.insert({
      calendarId: 'primary',
      resource: event,
    });
    console.log('Event created:', response.data.htmlLink);
    return response.data;
  } catch (error) {
    console.error('Error creating event:', error);
    throw new Error('Error creating event');
  }
}

// Define School schema
const schoolSchema = new mongoose.Schema({
  name: { type: String, required: true },
  code: { type: String, required: true, unique: true }
});
const School = mongoose.model('School', schoolSchema);

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, required: true },
  school: { type: String, required: true },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  grade: { type: String, required: true },
  classes: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Class' }],
  assignments: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Assignment' }],
  team: { type: mongoose.Schema.Types.ObjectId, ref: 'Team' },
  clubs: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Club' }],
  schoolTime: { start: String, end: String }
});
const User = mongoose.model('User', userSchema);

const classSchema = new mongoose.Schema({
  className: { type: String, required: true },
  subject: { type: String, required: true },
  period: { type: String, required: true },
  color: { type: String, required: true },
  teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  assignments: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Assignment' }]
});
const Class = mongoose.model('Class', classSchema);

const teamSchema = new mongoose.Schema({
  name: { type: String, required: true },
  coordinator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  practiceTimes: [{ start: Date, end: Date }]
});
const Team = mongoose.model('Team', teamSchema);

const clubSchema = new mongoose.Schema({
  name: { type: String, required: true },
  coordinator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  meetingTimes: [{ start: Date, end: Date }]
});
const Club = mongoose.model('Club', clubSchema);

const assignmentSchema = new mongoose.Schema({
  assignmentName: { type: String, required: true },
  durationHours: { type: Number, required: true },
  durationMinutes: { type: Number, required: true },
  points: { type: Number, required: true },
  category: { type: String, required: true },
  term: { type: String, required: true },
  rubric: { type: String },
  dueDate: { type: Date, required: true },
  files: [{ type: String }],
  class: { type: mongoose.Schema.Types.ObjectId, ref: 'Class' },
  students: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  turnedInStudents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  grades: [{
    student: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    grade: { type: Number },
    percentage: { type: Number }
  }]
});
const Assignment = mongoose.model('Assignment', assignmentSchema);

// Helper functions
async function calculateOverallGrade(studentId, classId) {
  try {
    const user = await User.findById(studentId).populate({
      path: 'assignments',
      populate: {
        path: 'class',
        match: { _id: classId },
      },
    });

    if (!user) {
      throw new Error('Student not found');
    }

    const assignments = user.assignments.filter(assignment => assignment.class && assignment.class._id.toString() === classId);

    let formativeTotalPoints = 0;
    let formativeScoredPoints = 0;
    let summativeTotalPoints = 0;
    let summativeScoredPoints = 0;

    assignments.forEach(assignment => {
      const grade = assignment.grades.find(g => g.student.toString() === studentId);
      if (grade) {
        if (assignment.category === 'Formative') {
          formativeTotalPoints += assignment.points;
          formativeScoredPoints += grade.grade;
        } else if (assignment.category === 'Summative') {
          summativeTotalPoints += assignment.points;
          summativeScoredPoints += grade.grade;
        }
      }
    });

    const formativePercentage = formativeTotalPoints > 0 ? (formativeScoredPoints / formativeTotalPoints) * 100 : 0;
    const summativePercentage = summativeTotalPoints > 0 ? (summativeScoredPoints / summativeTotalPoints) * 100 : 0;
    const overallPercentage = (formativePercentage * 0.2) + (summativePercentage * 0.8);

    return {
      formative: {
        totalPoints: formativeTotalPoints,
        scoredPoints: formativeScoredPoints,
        percentage: formativePercentage,
      },
      summative: {
        totalPoints: summativeTotalPoints,
        scoredPoints: summativeScoredPoints,
        percentage: summativePercentage,
      },
      overall: {
        percentage: overallPercentage,
      }
    };
  } catch (error) {
    console.error(`Error calculating grade for student ${studentId} in class ${classId}:`, error);
    return {
      formative: { totalPoints: 0, scoredPoints: 0, percentage: 0 },
      summative: { totalPoints: 0, scoredPoints: 0, percentage: 0 },
      overall: { percentage: 0 }
    };
  }
}

async function calculateOverallGradesForClasses(studentId, classIds) {
  const overallGrades = [];

  for (const classId of classIds) {
    const overallGrade = await calculateOverallGrade(studentId, classId);
    overallGrades.push({ 
      classId, 
      overall: overallGrade.overall,
      formative: overallGrade.formative,
      summative: overallGrade.summative
    });
  }

  return overallGrades;
}

function calculateGradeImpact(currentGrade, assignmentPoints, categoryWeight, classOverallGrade) {
  if (!classOverallGrade || !classOverallGrade.formative || !classOverallGrade.summative) {
    return 0;
  }

  const totalPoints = classOverallGrade.formative.totalPoints + classOverallGrade.summative.totalPoints + assignmentPoints;
  const scoredPoints = classOverallGrade.formative.scoredPoints + classOverallGrade.summative.scoredPoints;

  const newGrade = ((scoredPoints + assignmentPoints * categoryWeight) / totalPoints) * 100;

  return newGrade - currentGrade;
}

// API Endpoints
// Register endpoint
app.post('/register', async (req, res) => {
  const { email, password, role, schoolCode, firstName, lastName, grade } = req.body;

  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).send('Email already registered');
    }

    const school = await School.findOne({ code: schoolCode });
    if (!school) {
      return res.status(400).send('Invalid school code');
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = new User({ email, password: hashedPassword, role, school: school.name, firstName, lastName, grade });

    const savedUser = await user.save();
    const token = jwt.sign({ email: user.email, role: user.role, school: user.school }, secretKey, { expiresIn: '1h' });
    res.status(201).json({ token, role: user.role, school: user.school, firstName: user.firstName, lastName: user.lastName });
  } catch (error) {
    res.status(500).send('Error registering user');
  }
});

// Login endpoint
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) {
    return res.status(401).send('Invalid email or password');
  }
  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    return res.status(401).send('Invalid email or password');
  }
  const token = jwt.sign({ email: user.email, role: user.role, school: user.school }, secretKey, { expiresIn: '1h' });
  res.json({
    token,
    role: user.role,
    school: user.school,
    firstName: user.firstName,
    lastName: user.lastName,
    userId: user._id.toString(),
  });
});

// Add class endpoint
app.post('/classes', async (req, res) => {
  const { className, subject, period, color, teacher } = req.body;

  try {
    const teacherObjectId = new mongoose.Types.ObjectId(teacher);
    const newClass = new Class({ className, subject, period, color, teacher: teacherObjectId });
    const savedClass = await newClass.save();
    res.status(201).json(savedClass);
  } catch (error) {
    console.error('Error adding class:', error);
    res.status(500).send(`Error adding class: ${error.message}`);
  }
});

// Add students to class endpoint
app.post('/classes/addStudents', async (req, res) => {
  const { className, students } = req.body;
  console.log(`Adding students to class: ${className}, Students: ${students}`);

  try {
    const classObjectId = new mongoose.Types.ObjectId(className);
    const classDoc = await Class.findById(classObjectId);
    if (!classDoc) {
      console.log('Class not found');
      return res.status(404).send('Class not found');
    }

    if (students.length === 0) {
      console.log('No students selected');
      return res.status(200).send('No students added to class');
    }

    students.forEach(studentId => {
      const objectId = new mongoose.Types.ObjectId(studentId);
      if (!classDoc.students.includes(objectId)) {
        classDoc.students.push(objectId);
      }
    });

    const userIds = students.map(studentId => new mongoose.Types.ObjectId(studentId));
    console.log(`User IDs to update: ${userIds}`);
    await User.updateMany({ _id: { $in: userIds } }, { $push: { classes: classDoc._id } });

    await classDoc.save();
    res.status(200).send('Students added to class');
  } catch (error) {
    console.error('Error adding students to class:', error);
    res.status(500).send(`Error adding students to class: ${error.message}`);
  }
});

// Add new team or club
app.post('/extracurricular', async (req, res) => {
  const { type, name, coordinatorId, additionalInfo } = req.body;

  try {
    let savedExtracurricular;
    if (type === 'team') {
      savedExtracurricular = new Team({ name, coordinator: coordinatorId, additionalInfo });
    } else if (type === 'club') {
      savedExtracurricular = new Club({ name, coordinator: coordinatorId, additionalInfo });
    }

    await savedExtracurricular.save();
    res.status(201).json(savedExtracurricular);
  } catch (error) {
    res.status(500).send('Error creating extracurricular activity');
  }
});

// Add students to team or club
app.post('/extracurricular/:id/students', async (req, res) => {
  const { id } = req.params;
  const { studentIds, type } = req.body;

  try {
    let extracurricular;
    if (type === 'team') {
      extracurricular = await Team.findById(id);
    } else if (type === 'club') {
      extracurricular = await Club.findById(id);
    }

    if (!extracurricular) {
      return res.status(404).send('Extracurricular activity not found');
    }

    studentIds.forEach(studentId => {
      if (!extracurricular.students.includes(studentId)) {
        extracurricular.students.push(studentId);
      }
    });

    await extracurricular.save();
    await User.updateMany(
      { _id: { $in: studentIds } },
      { $push: { [type === 'team' ? 'team' : 'clubs']: id } }
    );

    res.status(200).send('Students added to extracurricular activity');
  } catch (error) {
    res.status(500).send('Error adding students to extracurricular activity');
  }
});

// Schedule practice or meeting times
app.post('/extracurricular/:id/times', async (req, res) => {
  const { id } = req.params;
  const { start, end, type } = req.body;

  try {
    let extracurricular;
    if (type === 'team') {
      extracurricular = await Team.findById(id);
    } else if (type === 'club') {
      extracurricular = await Club.findById(id);
    }

    if (!extracurricular) {
      return res.status(404).send('Extracurricular activity not found');
    }

    if (type === 'team') {
      extracurricular.practiceTimes.push({ start, end });
    } else if (type === 'club') {
      extracurricular.meetingTimes.push({ start, end });
    }

    await extracurricular.save();
    res.status(200).send('Time scheduled');
  } catch (error) {
    res.status(500).send('Error scheduling time');
  }
});

// Set school time for student
app.post('/students/:studentId/school-time', async (req, res) => {
  const { studentId } = req.params;
  const { start, end } = req.body;

  try {
    const student = await User.findById(studentId);
    if (!student) {
      return res.status(404).send('Student not found');
    }

    student.schoolTime = { start, end };
    await student.save();

    res.status(200).send('School time set');
  } catch (error) {
    res.status(500).send('Error setting school time');
  }
});

// Get available time slots for student
app.get('/students/:studentId/available-time-slots', async (req, res) => {
  const { studentId } = req.params;

  try {
    const student = await User.findById(studentId).populate('team clubs');
    if (!student) {
      return res.status(404).send('Student not found');
    }

    const schoolTime = student.schoolTime;
    const schoolStart = new Date(`1970-01-01T${schoolTime.start}:00Z`);
    const schoolEnd = new Date(`1970-01-01T${schoolTime.end}:00Z`);

    const practiceTimes = student.team ? student.team.practiceTimes : [];
    const meetingTimes = student.clubs.flatMap(club => club.meetingTimes);

    const busyTimes = [...practiceTimes, ...meetingTimes];

    const availableSlots = [];
    const dayStart = new Date(`1970-01-01T00:00:00Z`);
    const dayEnd = new Date(`1970-01-01T23:59:59Z`);

    for (let time = dayStart; time < dayEnd; time.setMinutes(time.getMinutes() + 30)) {
      const slotStart = new Date(time);
      const slotEnd = new Date(time);
      slotEnd.setMinutes(slotEnd.getMinutes() + 30);

      if (slotStart >= schoolStart && slotEnd <= schoolEnd) {
        continue;
      }

      const conflicts = busyTimes.some(busyTime => {
        const busyStart = new Date(busyTime.start);
        const busyEnd = new Date(busyTime.end);
        return (slotStart >= busyStart && slotStart < busyEnd) || (slotEnd > busyStart && slotEnd <= busyEnd);
      });

      if (!conflicts) {
        availableSlots.push({ start: slotStart, end: slotEnd });
      }
    }

    res.json(availableSlots);
  } catch (error) {
    res.status(500).send('Error fetching available time slots');
  }
});

// Fill calendar with assignments
app.post('/students/:studentId/fill-calendar', async (req, res) => {
  const { studentId } = req.params;

  try {
    const assignments = await Assignment.find({
      students: studentId,
      turnedInStudents: { $ne: studentId },
    }).populate('class');

    const availableSlots = await getAvailableTimeSlots(studentId);
    let calendarEvents = [];

    assignments.sort((a, b) => {
      const aPriority = calculatePriority(a);
      const bPriority = calculatePriority(b);
      return bPriority - aPriority;
    });

    assignments.forEach(assignment => {
      const duration = (assignment.durationHours * 60) + assignment.durationMinutes;

      for (let slot of availableSlots) {
        const slotDuration = (slot.end - slot.start) / (1000 * 60);
        if (slotDuration >= duration) {
          calendarEvents.push({
            summary: `Work on ${assignment.assignmentName}`,
            description: `${assignment.class.className} - ${assignment.category} assignment`,
            start: slot.start,
            end: new Date(slot.start.getTime() + duration * 60000),
          });

          slot.start = new Date(slot.start.getTime() + duration * 60000);
          break;
        }
      }
    });

    res.json(calendarEvents);
  } catch (error) {
    res.status(500).send('Error filling calendar with assignments');
  }
});

async function getAvailableTimeSlots(studentId) {
  const student = await User.findById(studentId).populate('team clubs');
  const schoolTime = student.schoolTime;
  const schoolStart = new Date(`1970-01-01T${schoolTime.start}:00Z`);
  const schoolEnd = new Date(`1970-01-01T${schoolTime.end}:00Z`);

  const practiceTimes = student.team ? student.team.practiceTimes : [];
  const meetingTimes = student.clubs.flatMap(club => club.meetingTimes);

  const busyTimes = [...practiceTimes, ...meetingTimes];

  const availableSlots = [];
  const dayStart = new Date(`1970-01-01T00:00:00Z`);
  const dayEnd = new Date(`1970-01-01T23:59:59Z`);

  for (let time = dayStart; time < dayEnd; time.setMinutes(time.getMinutes() + 30)) {
    const slotStart = new Date(time);
    const slotEnd = new Date(time);
    slotEnd.setMinutes(slotEnd.getMinutes() + 30);

    if (slotStart >= schoolStart && slotEnd <= schoolEnd) {
      continue;
    }

    const conflicts = busyTimes.some(busyTime => {
      const busyStart = new Date(busyTime.start);
      const busyEnd = new Date(busyTime.end);
      return (slotStart >= busyStart && slotStart < busyEnd) || (slotEnd > busyStart && slotEnd <= busyEnd);
    });

    if (!conflicts) {
      availableSlots.push({ start: slotStart, end: slotEnd });
    }
  }

  return availableSlots;
}

function calculatePriority(assignment) {
  const dueDate = new Date(assignment.dueDate);
  const now = new Date();
  const daysUntilDue = (dueDate - now) / (1000 * 60 * 60 * 24);

  const categoryWeight = assignment.category === 'Summative' ? 0.8 : 0.2;
  const pointsWeight = assignment.points;

  return (1 / daysUntilDue) + (categoryWeight * 10) + (pointsWeight / 10);
}

// Add assignment to class endpoint
app.post('/classes/:classId/assignments', async (req, res) => {
  const { classId } = req.params;
  const { assignmentName, durationHours, durationMinutes, points, category, term, rubric, dueDate, files, teacher } = req.body;

  try {
    const classDoc = await Class.findById(classId).populate('students');
    if (!classDoc) {
      return res.status(404).send('Class not found');
    }

    const duration = (parseInt(durationHours) * 60) + parseInt(durationMinutes);

    const newAssignment = new Assignment({
      assignmentName,
      durationHours: parseInt(durationHours),
      durationMinutes: parseInt(durationMinutes),
      duration,
      points,
      category,
      term,
      rubric,
      dueDate: new Date(dueDate),
      files,
      class: classDoc._id,
      students: classDoc.students.map(student => student._id),
      teacher: teacher
    });
    const savedAssignment = await newAssignment.save();

    await User.updateMany(
      { _id: { $in: classDoc.students.map(student => student._id) } },
      { $push: { assignments: savedAssignment._id } }
    );

    classDoc.assignments.push(savedAssignment._id);
    await classDoc.save();

    const startDate = new Date(dueDate);
    const endDate = new Date(startDate);
    endDate.setHours(startDate.getHours() + parseInt(durationHours));
    endDate.setMinutes(startDate.getMinutes() + parseInt(durationMinutes));

    const eventDetails = {
      summary: assignmentName,
      description: `${category} assignment for ${classDoc.className}`,
      start: startDate.toISOString(),
      end: endDate.toISOString(),
    };

    await addEventToCalendar(eventDetails);

    res.status(201).json({ message: 'Assignment added successfully', assignment: savedAssignment });
  } catch (error) {
    console.error('Error adding assignment:', error);
    res.status(500).send('Error adding assignment');
  }
});

// Fetch assignments for a specific class
app.get('/classes/:className/assignments', async (req, res) => {
  const className = req.params.className;

  try {
    const classDoc = await Class.findOne({ className }).populate('assignments');
    if (!classDoc) {
      return res.status(404).send('Class not found');
    }

    res.json(classDoc.assignments);
  } catch (error) {
    console.error('Error fetching assignments:', error);
    res.status(500).send('Error fetching assignments');
  }
});

// Fetch assignments for a specific student
app.get('/students/:studentId/assignments', async (req, res) => {
  const studentId = req.params.studentId;
  const { status } = req.query;
  const now = new Date();

  try {
    const user = await User.findById(studentId).populate({
      path: 'assignments',
      populate: {
        path: 'class',
        select: 'className',
      },
    });

    if (!user) {
      return res.status(404).send('Student not found');
    }

    let assignments = user.assignments.map(assignment => ({
      id: assignment._id,
      assignmentName: assignment.assignmentName,
      durationHours: assignment.durationHours,
      durationMinutes: assignment.durationMinutes,
      points: assignment.points,
      category: assignment.category,
      term: assignment.term,
      rubric: assignment.rubric,
      dueDate: assignment.dueDate,
      dueDateFormatted: moment(assignment.dueDate).format('MMM DD, YYYY [at] hh:mm A'),
      files: assignment.files,
      className: assignment.class ? assignment.class.className : 'Class Not Found',
      turnedIn: assignment.turnedInStudents.includes(studentId),
    }));

    if (status === 'current') {
      assignments = assignments.filter(assignment => new Date(assignment.dueDate) >= now && !assignment.turnedIn);
    } else if (status === 'past-due') {
      assignments = assignments.filter(assignment => new Date(assignment.dueDate) < now && !assignment.turnedIn);
    } else if (status === 'completed') {
      assignments = assignments.filter(assignment => assignment.turnedIn);
    }

    res.json(assignments);
  } catch (error) {
    console.error('Error fetching assignments for student:', error);
    res.status(500).send(`Error fetching assignments for student: ${error.message}`);
  }
});

// Fetch classes for a specific student
app.get('/students/:studentId/classes', async (req, res) => {
  const studentId = req.params.studentId;
  console.log(`Received request for student classes. UserId: ${studentId}`);

  if (!studentId) {
    console.log('UserId is missing or empty');
    return res.status(400).send('UserId is required');
  }

  try {
    const user = await User.findById(studentId).populate('classes');
    if (!user) {
      console.log(`User not found for userId: ${studentId}`);
      return res.status(404).send('Student not found');
    }
    const classes = user.classes;
    res.json(classes);
  } catch (error) {
    console.error('Error fetching classes for student:', error);
    res.status(500).send('Error fetching classes for student');
  }
});

// Fetch classes endpoint
app.get('/classes', async (req, res) => {
  const teacher = req.query.teacher;
  try {
    const classes = await Class.find({ teacher });
    res.json(classes);
  } catch (error) {
    res.status(500).send('Error fetching classes');
  }
});

// Fetch students endpoint
app.get('/students', async (req, res) => {
  const school = req.query.school;
  console.log(`Fetching students for school: ${school}`);
  try {
    const students = await User.find({ school: school, role: 'student' });
    console.log(`Found students: ${JSON.stringify(students)}`);
    res.json(students);
  } catch (error) {
    console.error('Error fetching students', error);
    res.status(500).send('Error fetching students');
  }
});

// Turn in assignment endpoint
app.post('/assignments/:assignmentId/turn-in', async (req, res) => {
  const { assignmentId } = req.params;
  const { studentId } = req.body;

  try {
    const assignment = await Assignment.findById(assignmentId);
    if (!assignment) {
      return res.status(404).send('Assignment not found');
    }

    const student = await User.findById(studentId);
    if (!student) {
      return res.status(404).send('Student not found');
    }

    const updatedAssignment = await Assignment.findByIdAndUpdate(
      assignmentId,
      { $addToSet: { turnedInStudents: studentId } },
      { new: true, runValidators: false }
    );

    if (!updatedAssignment) {
      return res.status(404).send('Assignment not found');
    }

    res.status(200).json({ message: 'Assignment turned in successfully' });
  } catch (error) {
    console.error('Error turning in assignment:', error);
    return res.status(500).send(`Error turning in assignment: ${error.message}`);
  }
});

// Fetch classes for a specific teacher
app.get('/teachers/:teacherId/classes', async (req, res) => {
  const { teacherId } = req.params;

  try {
    const classes = await Class.find({ teacher: teacherId });
    if (!classes.length) {
      return res.status(404).send('No classes found for this teacher');
    }
    res.status(200).json(classes);
  } catch (error) {
    console.error('Error fetching classes for teacher:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Fetch assignments to grade for a specific teacher
app.get('/teachers/:teacherId/assignments-to-grade', async (req, res) => {
  const { teacherId } = req.params;

  try {
    const assignments = await Assignment.find({
      teacher: teacherId,
      turnedInStudents: { $exists: true, $ne: [] }
    }).populate('turnedInStudents class');

    if (assignments.length === 0) {
      return res.status(404).json({ message: 'No turned-in assignments found for this teacher' });
    }

    const assignmentsToGrade = assignments.map(assignment => ({
      id: assignment._id,
      assignmentName: assignment.assignmentName,
      className: assignment.class ? assignment.class.className : 'Class Not Found',
      students: assignment.turnedInStudents.map(student => ({
        studentId: student._id,
        studentName: `${student.firstName} ${student.lastName}`,
      })),
      points: assignment.points,
      category: assignment.category,
      rubric: assignment.rubric,
      dueDate: assignment.dueDate,
      durationHours: assignment.durationHours,
      durationMinutes: assignment.durationMinutes,
      files: assignment.files,
    }));

    res.json(assignmentsToGrade);
  } catch (error) {
    console.error('Error fetching assignments to grade:', error);
    res.status(500).send('Error fetching assignments to grade');
  }
});

// Score assignment endpoint
app.post('/assignments/:assignmentId/score', async (req, res) => {
  const { assignmentId } = req.params;
  const { studentId, grade } = req.body;

  console.log('Received request to score assignment:');
  console.log('Assignment ID:', assignmentId);
  console.log('Student ID:', studentId);
  console.log('Grade:', grade);

  try {
    const assignment = await Assignment.findById(assignmentId);
    if (!assignment) {
      return res.status(404).send('Assignment not found');
    }

    const student = await User.findById(studentId);
    if (!student) {
      return res.status(404).send('Student not found');
    }

    if (grade > assignment.points) {
      return res.status(400).send('Score is more than 100%');
    }

    const percentage = (grade / assignment.points) * 100;

    const existingGradeIndex = assignment.grades.findIndex(g => g.student.toString() === studentId);
    if (existingGradeIndex !== -1) {
      assignment.grades[existingGradeIndex].grade = grade;
      assignment.grades[existingGradeIndex].percentage = percentage;
    } else {
      assignment.grades.push({ student: studentId, grade, percentage });
    }

    await assignment.save();
    res.status(200).send('Score saved successfully');
  } catch (error) {
    console.error('Error scoring assignment:', error);
    res.status(500).send('Error scoring assignment');
  }
});

// Fetch grades for a specific student
app.get('/students/:studentId/grades', async (req, res) => {
  const { studentId } = req.params;

  console.log(`Fetching grades for student ID: ${studentId}`);

  try {
    const user = await User.findById(studentId).populate({
      path: 'assignments',
      populate: {
        path: 'class',
        select: 'className',
      },
    });

    if (!user) {
      console.log('Student not found');
      return res.status(404).send('Student not found');
    }

    console.log('User found:', user);

    const grades = user.assignments.map(assignment => {
      const grade = assignment.grades.find(g => g.student.toString() === studentId);
      return {
        assignmentName: assignment.assignmentName,
        className: assignment.class ? assignment.class.className : 'Class Not Found',
        grade: grade ? grade.grade : 'Not graded',
        percentage: grade ? grade.percentage : 'N/A',
        points: assignment.points,
        category: assignment.category,
        term: assignment.term,
        dueDate: moment(assignment.dueDate).format('MMM DD, YYYY [at] hh:mm A'),
      };
    });

    console.log('Grades fetched:', grades);

    res.json(grades);
  } catch (error) {
    console.error('Error fetching grades:', error);
    res.status(500).send('Error fetching grades');
  }
});

// Add event to Google Calendar
app.post('/calendar/add-event', async (req, res) => {
  const { summary, description, start, end } = req.body;

  try {
    const eventDetails = { summary, description, start, end };
    const event = await addEventToCalendar(eventDetails);
    res.status(200).json({ message: 'Event created successfully', event });
  } catch (error) {
    res.status(500).send('Error creating calendar event');
  }
});

app.get('/', async (req, res) => {
  const { code } = req.query;
  if (!code) {
      return res.status(400).send('Authorization code not found');
  }

  try {
      const { tokens } = await oAuth2Client.getToken(code);
      oAuth2Client.setCredentials(tokens);
      fs.writeFile(TOKEN_PATH, JSON.stringify(tokens), (err) => {
          if (err) return console.error('Error saving the token', err);
          console.log('Token stored to', TOKEN_PATH);
      });
      res.send('Authorization successful, token stored.');
  } catch (error) {
      console.error('Error retrieving access token', error);
      res.status(500).send('Error retrieving access token');
  }
});

// Fetch calendar events for a user
app.get('/calendar/events', async (req, res) => {
  const userId = req.query.userId;
  try {
    const events = await Event.find({ userId });
    res.json(events);
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).send('Error fetching events');
  }
});

// Fetch overall grades for a specific student and class for a term
app.get('/students/:studentId/classes/:classId/grades/overall/:term', async (req, res) => {
  const { studentId, classId, term } = req.params;

  try {
    const user = await User.findById(studentId).populate({
      path: 'assignments',
      populate: {
        path: 'class',
        match: { _id: classId },
      },
    });

    if (!user) {
      return res.status(404).send('Student not found');
    }

    const assignments = user.assignments.filter(assignment => assignment.class && assignment.class._id.toString() === classId && assignment.term === term);

    let formativeTotalPoints = 0;
    let formativeScoredPoints = 0;
    let summativeTotalPoints = 0;
    let summativeScoredPoints = 0;

    assignments.forEach(assignment => {
      const grade = assignment.grades.find(g => g.student.toString() === studentId);
      if (grade) {
        if (assignment.category === 'Formative') {
          formativeTotalPoints += assignment.points;
          formativeScoredPoints += grade.grade;
        } else if (assignment.category === 'Summative') {
          summativeTotalPoints += assignment.points;
          summativeScoredPoints += grade.grade;
        }
      }
    });

    const formativePercentage = formativeTotalPoints > 0 ? (formativeScoredPoints / formativeTotalPoints) * 100 : 0;
    const summativePercentage = summativeTotalPoints > 0 ? (summativeScoredPoints / summativeTotalPoints) * 100 : 0;
    const overallPercentage = (formativePercentage * 0.2) + (summativePercentage * 0.8);

    res.json({
      term,
      formative: {
        totalPoints: formativeTotalPoints,
        scoredPoints: formativeScoredPoints,
        percentage: formativePercentage.toFixed(2),
      },
      summative: {
        totalPoints: summativeTotalPoints,
        scoredPoints: summativeScoredPoints,
        percentage: summativePercentage.toFixed(2),
      },
      overall: {
        percentage: overallPercentage.toFixed(2),
      }
    });
  } catch (error) {
    console.error('Error calculating overall grades:', error);
    res.status(500).send('Error calculating overall grades');
  }
});

// Fetch assignments for a specific student and class for a term
app.get('/students/:studentId/classes/:classId/assignments/:term', async (req, res) => {
  const { studentId, classId, term } = req.params;

  try {
    const user = await User.findById(studentId).populate({
      path: 'assignments',
      populate: {
        path: 'class',
        match: { _id: classId },
      },
    });

    if (!user) {
      return res.status(404).send('Student not found');
    }

    const assignments = user.assignments.filter(assignment => 
      assignment.class && 
      assignment.class._id.toString() === classId && 
      assignment.term === term
    );

    const assignmentsWithGrades = assignments.map(assignment => {
      const grade = assignment.grades.find(g => g.student.toString() === studentId);
      return {
        id: assignment._id,
        assignmentName: assignment.assignmentName,
        dueDate: assignment.dueDate,
        dueDateFormatted: moment(assignment.dueDate).format('MMM DD, YYYY [at] hh:mm A'),
        points: assignment.points,
        category: assignment.category,
        grade: grade ? grade.grade : 'Not graded',
        percentage: grade ? grade.percentage : 'N/A',
        turnedIn: assignment.turnedInStudents.includes(studentId),
      };
    });

    res.json(assignmentsWithGrades);
  } catch (error) {
    console.error('Error fetching assignments:', error);
    res.status(500).send('Error fetching assignments');
  }
});

// Fetch weighted overall grades for a specific student and class
app.get('/students/:studentId/classes/:classId/grades/overall-weighted', async (req, res) => {
  const { studentId, classId } = req.params;

  try {
    const user = await User.findById(studentId).populate({
      path: 'assignments',
      populate: {
        path: 'class',
        match: { _id: classId },
      },
    });

    if (!user) {
      return res.status(404).send('Student not found');
    }

    const assignments = user.assignments.filter(assignment => assignment.class && assignment.class._id.toString() === classId);

    const termGrades = {};

    assignments.forEach(assignment => {
      const grade = assignment.grades.find(g => g.student.toString() === studentId);
      if (grade) {
        if (!termGrades[assignment.term]) {
          termGrades[assignment.term] = {
            formativeTotalPoints: 0,
            formativeScoredPoints: 0,
            summativeTotalPoints: 0,
            summativeScoredPoints: 0,
          };
        }

        if (assignment.category === 'Formative') {
          termGrades[assignment.term].formativeTotalPoints += assignment.points;
          termGrades[assignment.term].formativeScoredPoints += grade.grade;
        } else if (assignment.category === 'Summative') {
          termGrades[assignment.term].summativeTotalPoints += assignment.points;
          termGrades[assignment.term].summativeScoredPoints += grade.grade;
        }
      }
    });

    const termResults = Object.keys(termGrades).map(term => {
      const formativePercentage = termGrades[term].formativeTotalPoints > 0 ? (termGrades[term].formativeScoredPoints / termGrades[term].formativeTotalPoints) * 100 : 0;
      const summativePercentage = termGrades[term].summativeTotalPoints > 0 ? (termGrades[term].summativeScoredPoints / termGrades[term].summativeTotalPoints) * 100 : 0;
      const overallPercentage = (formativePercentage * 0.2) + (summativePercentage * 0.8);

      return {
        term,
        formative: {
          totalPoints: termGrades[term].formativeTotalPoints,
          scoredPoints: termGrades[term].formativeScoredPoints,
          percentage: formativePercentage.toFixed(2),
        },
        summative: {
          totalPoints: termGrades[term].summativeTotalPoints,
          scoredPoints: termGrades[term].summativeScoredPoints,
          percentage: summativePercentage.toFixed(2),
        },
        overall: {
          percentage: overallPercentage.toFixed(2),
        }
      };
    });

    res.json(termResults);
  } catch (error) {
    console.error('Error calculating overall grades:', error);
    res.status(500).send('Error calculating overall grades');
  }
});

// Endpoint to get prioritized to-do list for a student across all classes
app.get('/students/:studentId/todo-priority', async (req, res) => {
  const { studentId } = req.params;

  try {
    console.log(`Fetching student with ID: ${studentId}`);
    const user = await User.findById(studentId).populate({
      path: 'assignments',
      populate: {
        path: 'class',
      },
    });

    if (!user) {
      console.log('Student not found');
      return res.status(404).send('Student not found');
    }

    console.log(`Student found: ${user.firstName} ${user.lastName}`);

    const classIds = user.classes.map(cls => cls._id);
    console.log(`Class IDs: ${classIds}`);

    const assignments = await Assignment.find({ class: { $in: classIds }, students: studentId }).populate('class');
    console.log(`Assignments found: ${assignments.length}`);

    const overallGrades = await calculateOverallGradesForClasses(studentId, classIds);
    console.log('Overall grades calculated');

    const now = new Date();

    const prioritizedAssignments = assignments.map(assignment => {
      const dueDate = new Date(assignment.dueDate);
      const daysUntilDue = Math.max((dueDate - now) / (1000 * 60 * 60 * 24), 0.1);

      const categoryWeight = assignment.category === 'Summative' ? 0.8 : 0.2;
      const pointsWeight = assignment.points;
      const classOverallGrade = overallGrades.find(grade => grade.classId.toString() === assignment.class._id.toString());
      const currentGrade = classOverallGrade && classOverallGrade.overall ? classOverallGrade.overall.percentage : 0;
      const potentialGradeImpact = calculateGradeImpact(
        currentGrade,
        assignment.points,
        categoryWeight,
        classOverallGrade
      );

      const currentGradeWeight = currentGrade < 70 ? 1.2 : 1;

      const priorityScore = ((1 / daysUntilDue) + (categoryWeight * 10) + (pointsWeight / 10) + potentialGradeImpact) * currentGradeWeight;

      return {
        id: assignment._id,
        assignmentName: assignment.assignmentName,
        category: assignment.category,
        points: assignment.points,
        dueDate: assignment.dueDate,
        dueDateFormatted: moment(assignment.dueDate).format('MMM DD, YYYY [at] hh:mm A'),
        className: assignment.class.className,
        turnedIn: assignment.turnedInStudents.includes(studentId),
        priorityScore: priorityScore.toFixed(2),
        currentGrade: currentGrade.toFixed(2),
        potentialImpact: potentialGradeImpact.toFixed(2),
        status: dueDate < now ? 'past-due' : 'current'
      };
    });

    const filteredAssignments = prioritizedAssignments
      .filter(assignment => !assignment.turnedIn)
      .sort((a, b) => {
        if (a.status === 'past-due' && b.status !== 'past-due') return -1;
        if (a.status !== 'past-due' && b.status === 'past-due') return 1;
        return b.priorityScore - a.priorityScore;
      });

    res.json(filteredAssignments);
  } catch (error) {
    console.error('Error generating to-do priority list:', error);
    res.status(500).send('Error generating to-do priority list');
  }
});

// Add this new endpoint for undoing turn-in assignments
app.post('/assignments/:assignmentId/undo-turn-in', async (req, res) => {
  const { assignmentId } = req.params;
  const { studentId } = req.body;

  try {
    const assignment = await Assignment.findById(assignmentId).populate('grades.student');
    if (!assignment) {
      return res.status(404).send('Assignment not found');
    }

    const grade = assignment.grades.find(g => g.student._id.toString() === studentId);
    if (grade) {
      return res.status(400).send('Cannot undo turn-in for graded assignment');
    }

    assignment.turnedInStudents = assignment.turnedInStudents.filter(student => student.toString() !== studentId);
    await assignment.save();

    res.status(200).json({ message: 'Turn-in undone successfully' });
  } catch (error) {
    console.error('Error undoing turn-in:', error);
    res.status(500).send(`Error undoing turn-in: ${error.message}`);
  }
});

// Protected endpoint
app.get('/protected', (req, res) => {
  const token = req.headers['authorization'];
  if (!token) {
    return res.status(401).send('Access denied');
  }
  try {
    const decoded = jwt.verify(token, secretKey);
    res.json({ message: 'This is a protected route', user: decoded });
  } catch (err) {
    res.status(401).send('Invalid token');
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
