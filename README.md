# Flowra - Women's Period Tracker & Safety App

A comprehensive Flutter web application for period cycle tracking, health logging, and women's safety with AI-powered insights and emergency features.

---

## 📋 Project Overview

**Flowra** is a feature-rich college project combining:
- **Frontend:** Flutter (Web App)
- **Backend:** Python FastAPI
- **Database & Auth:** Firebase (Realtime Database + Authentication)

The app empowers women with health insights, safety features, and wellness guidance while maintaining strict privacy standards.

---

## ✨ Core Features

### 1. **Authentication & User Management**
- User registration with email/password
- Secure login system
- User profile management
- Privacy-focused data handling

### 2. **Period Cycle Tracking**
- Manual period date entry
- Automated cycle predictions based on historical data
- Cycle length calculations
- Ovulation window estimation
- Period notifications (optional)

### 3. **Health Logging**
- Daily mood tracking (emojis: Happy, Neutral, Sad, Anxious)
- Energy level logging (1-10 scale)
- Pain tracking (location + intensity)
- Flexible logging anytime
- Historical data visualization with trends

### 4. **Period-Aware Insights & Analytics**
- AI-generated **weekly summaries** (simpler local approach for beginners)
- Correlation analysis: How mood/pain/energy relate to period phases
- Cycle predictions and insights
- Weekly wellness recommendations

### 5. **Emergency Safety Features**
- **Smart SOS Button** - One-tap emergency alert
- **Trusted Contacts** (3-5 contacts)
  - Add/edit/delete trusted contacts
  - Emergency alerts to contacts
- **Location Sharing** during emergencies
  - Share real-time location with trusted contacts
  - Auto-capture location during SOS

### 6. **Guided Self-Care & Wellness**
- 3 starter self-care sessions with:
  - Text-based guides
  - Embedded video content
  - Session tracking/completion status
- Topics: Stress relief, period pain management, relaxation techniques

### 7. **Privacy & Security**
- End-to-end data encryption for sensitive health info
- User data never shared without consent
- Secure authentication
- GDPR-compliant data handling
- Private mode for sensitive logging

---

## 🏗️ Architecture

### Frontend Architecture (Flutter)

```
lib/
├── main.dart                 # App entry point with Firebase init
├── models/                   # Data models
│   ├── cycle_model.dart
│   ├── health_log_model.dart
│   ├── user_model.dart
│   ├── trusted_contact_model.dart
│   └── wellness_session_model.dart
├── screens/                  # UI Screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── cycle_tracker_screen.dart
│   ├── health_logging_screen.dart
│   ├── insights_screen.dart
│   ├── sos_screen.dart
│   ├── wellness_screen.dart
│   ├── trusted_contacts_screen.dart
│   └── settings_screen.dart
├── services/                 # Business logic & API calls
│   ├── auth_service.dart
│   ├── firebase_service.dart
│   ├── user_service.dart
│   ├── cycle_service.dart
│   ├── health_log_service.dart
│   ├── insights_service.dart
│   ├── sos_service.dart
│   ├── location_service.dart
│   └── wellness_service.dart
├── widgets/                  # Reusable UI components
│   ├── primary_button.dart
│   ├── mood_card.dart
│   ├── cycle_calendar.dart
│   ├── health_chart.dart
│   └── navigation_bar.dart
└── utils/                    # Utilities
    ├── constants.dart
    ├── helpers.dart
    └── validators.dart
```

### Backend Architecture (Python FastAPI)

```
backend/
├── main.py                   # FastAPI app entry
├── config.py                 # Configuration & Firebase setup
├── requirements.txt          # Python dependencies
├── routes/
│   ├── auth_routes.py
│   ├── cycle_routes.py
│   ├── health_log_routes.py
│   ├── insights_routes.py
│   ├── sos_routes.py
│   ├── wellness_routes.py
│   └── trusted_contacts_routes.py
├── services/
│   ├── firebase_service.py
│   ├── insights_service.py   # AI/ML logic for insights
│   ├── location_service.py
│   └── notification_service.py
├── models/
│   ├── user_model.py
│   ├── cycle_model.py
│   ├── health_log_model.py
│   └── trusted_contact_model.py
└── utils/
    ├── helpers.py
    └── validators.py
```

### Data Flow

```
Flutter UI ──────> FastAPI Backend ──────> Firebase
  (Web App)      (Python API Layer)    (DB + Auth)
     ↓                  ↓                    ↓
  User Input     Business Logic      Realtime Sync
  Display Data   AI Insights
                 Location Handling
```

---

## 📊 Database Schema (Firebase Realtime Database)

```
flowra-9584d/
├── users/
│   ├── {userId}/
│   │   ├── email
│   │   ├── displayName
│   │   ├── createdAt
│   │   ├── lastUpdated
│   │   └── settings
│   │       ├── notificationsEnabled
│   │       └── privacyMode
├── cycles/
│   ├── {userId}/
│   │   ├── {cycleId}/
│   │   │   ├── startDate
│   │   │   ├── endDate
│   │   │   ├── cycleLength
│   │   │   ├── periodLength
│   │   │   └── notes
├── health_logs/
│   ├── {userId}/
│   │   ├── {logId}/
│   │   │   ├── date
│   │   │   ├── mood (1-5)
│   │   │   ├── energy (1-10)
│   │   │   ├── pain
│   │   │   │   ├── intensity (1-10)
│   │   │   │   ├── location
│   │   │   │   └── notes
│   │   │   └── timestamp
├── trusted_contacts/
│   ├── {userId}/
│   │   ├── {contactId}/
│   │   │   ├── name
│   │   │   ├── phone
│   │   │   ├── email
│   │   │   ├── relationship
│   │   │   └── isActive
├── sos_alerts/
│   ├── {userId}/
│   │   ├── {alertId}/
│   │   │   ├── timestamp
│   │   │   ├── latitude
│   │   │   ├── longitude
│   │   │   ├── message
│   │   │   ├── contactsNotified
│   │   │   └── status
├── insights/
│   ├── {userId}/
│   │   ├── {weekId}/
│   │   │   ├── week (e.g., "2026-W05")
│   │   │   ├── summary (AI generated text)
│   │   │   ├── moodTrend
│   │   │   ├── energyTrend
│   │   │   ├── painTrend
│   │   │   ├── cyclePhase
│   │   │   ├── recommendations
│   │   │   └── generatedAt
└── wellness_sessions/
    ├── {sessionId}/
    │   ├── title
    │   ├── category (stress-relief, pain-management, etc.)
    │   ├── description
    │   ├── videoUrl (optional)
    │   ├── textContent
    │   ├── duration (minutes)
    │   └── tags
```

---

## 🚀 Tech Stack Details

### Frontend (Flutter)
- **flutter**: Latest stable version
- **firebase_core**: Authentication & database
- **firebase_auth**: User authentication
- **firebase_database**: Realtime data sync
- **geolocator**: Location services for SOS
- **http**: API calls to FastAPI backend
- **charts_flutter**: Data visualization for trends
- **video_player**: Embedded video content
- **intl**: Internationalization & date formatting
- **provider**: State management (optional)

### Backend (FastAPI)
- **fastapi**: Web framework
- **uvicorn**: ASGI server
- **firebase-admin**: Firebase SDK
- **python-dotenv**: Environment variables
- **pydantic**: Data validation
- **requests**: HTTP calls
- **geopy**: Location services
- **numpy/pandas**: Data analysis for insights
- **python-dateutil**: Date calculations

### Services
- **Firebase**: Authentication, Realtime Database, Cloud Storage
- **OpenAI API** (Optional): Advanced AI insights (or simpler local approach)
- **Google Maps API** (Optional): Location mapping

---

## 📱 Feature Implementation Phases

### Phase 1: Core Foundation ✅ (This Week)
- [x] Firebase setup & configuration
- [ ] Login/Register screens
- [ ] User model & authentication service
- [ ] Navigation structure

### Phase 2: Period Tracking 📅
- [ ] Cycle entry interface
- [ ] Cycle model & database schema
- [ ] Cycle prediction algorithm
- [ ] Calendar view

### Phase 3: Health Logging 📊
- [ ] Mood/Energy/Pain logging UI
- [ ] Health log models & services
- [ ] Charts & trend visualization
- [ ] Historical data viewing

### Phase 4: Insights & Analytics 🤖
- [ ] Backend insights service
- [ ] Weekly summary generation
- [ ] Correlation analysis
- [ ] Insights display UI

### Phase 5: Safety Features 🆘
- [ ] SOS button & UI
- [ ] Trusted contacts management
- [ ] Location sharing implementation
- [ ] Emergency alert system

### Phase 6: Wellness & Polish ✨
- [ ] 3 wellness sessions (text + video)
- [ ] Settings & privacy controls
- [ ] UI/UX refinement
- [ ] Testing & documentation

---

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK (3.10.8+)
- Python 3.9+
- Firebase account (already configured)
- Git

### Frontend Setup
```bash
# Navigate to project root
cd c:\projects\flowra

# Get Flutter dependencies
flutter pub get

# Run web app
flutter run -d chrome
```

### Backend Setup
```bash
# Create backend directory
mkdir backend
cd backend

# Create virtual environment
python -m venv venv

# Activate venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Run FastAPI
uvicorn main:app --reload
```

---

## 🔐 Security & Privacy Considerations

1. **Authentication**: Firebase Auth handles secure login
2. **Data Encryption**: Sensitive health data encrypted at rest
3. **Location Data**: Only shared during active SOS, auto-deleted after 24 hours
4. **User Consent**: Explicit permission for contact sharing
5. **GDPR Compliance**: Users can request data deletion
6. **No Analytics**: No invasive tracking or third-party analytics
7. **Secure API**: FastAPI with HTTPS in production

---

## 📝 Implementation Notes

### Local AI Approach (Recommended for Beginners)
Instead of OpenAI API:
- Use simple Python logic to analyze mood/energy/pain trends
- Generate templates-based summaries with actual data
- Calculate averages and identify patterns
- Much cheaper and suitable for college projects

### Example Insight Logic
```python
# Pseudo code
weekly_avg_mood = average(all_moods_this_week)
weekly_avg_energy = average(all_energies_this_week)
if cycle_day in [1, 2, 3]:
    recommendation = "Consider resting more"
elif cycle_day in [14, 15]:
    recommendation = "Great day for exercise"
```

---

## 🎯 Success Criteria

- ✅ Firebase authentication working
- ✅ Period cycle tracking with predictions
- ✅ Daily health logging with trends
- ✅ Weekly AI insights generation
- ✅ SOS with trusted contacts
- ✅ Location sharing during emergencies
- ✅ 3 wellness sessions with text + video
- ✅ Privacy-first design
- ✅ Clean, intuitive UI

---

## 📞 Support & Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Firebase Docs](https://firebase.google.com/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

---

## 📄 License

College Project - For Educational Purposes Only

---

## ✍️ Author
Created for women's health and safety awareness

**Last Updated:** February 4, 2026

---

## Next Steps

1. ✅ README created with full architecture
2. 📝 Create authentication screens (Login/Register)
3. 🗄️ Set up data models
4. 📅 Implement cycle tracking feature
5. 📊 Build health logging interface
6. 🤖 Develop insights service
7. 🆘 Add emergency safety features
8. ✨ Polish UI/UX

**Ready to start implementing? Let me know which feature to build first!**
