const express = require('express');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const mongoose = require('mongoose');
const app = express();

app.use(bodyParser.json());
app.use(cors());

const secretKey = 'ClH9fA8J702JFLALvbCvA2fXXc7f1xznptYBKzT8mQE='; // Replace with your own secret key

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/mydb', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('Connected to MongoDB');
}).catch(err => {
  console.error('Error connecting to MongoDB', err);
});

// Define School schema
const schoolSchema = new mongoose.Schema({
  name: { type: String, required: true },
  code: { type: String, required: true, unique: true }
});

// Create School model
const School = mongoose.model('School', schoolSchema);

// Define User schema
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, required: true },
  school: { type: String, required: true } // Ensure this field is included
});

// Create User model
const User = mongoose.model('User', userSchema);

// Register endpoint
app.post('/register', async (req, res) => {
  const { email, password, role, schoolCode } = req.body;

  try {
    // Check if the email is already registered
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).send('Email already registered');
    }

    // Find the school by code
    const school = await School.findOne({ code: schoolCode });
    if (!school) {
      return res.status(400).send('Invalid school code');
    }

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create a new user instance
    const user = new User({ email, password: hashedPassword, role, school: school.name });

    // Save the new user to the database
    const savedUser = await user.save();
    console.log('User saved:', savedUser);
    res.status(201).send('User registered');
  } catch (error) {
    console.error('Error registering user:', error);
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
  res.json({ token, role: user.role, school: user.school });
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
