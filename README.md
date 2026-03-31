# Flodo - Task Management App

A full-stack task management application built with **Flutter** (frontend) and **Django** (backend). This app allows users to create, manage, and organize tasks with status tracking, due dates, and task dependencies.

## Features

### Core Features ✅
- **Task Management**: Create, Read, Update, and Delete tasks
- **Task Fields**: 
  - Title (required)
  - Description (optional)
  - Due Date (required)
  - Status (To-Do, In Progress, Done)
  - Blocked By (Optional: Link to another task)
- **Search & Filter**: 
  - Search tasks by title in real-time
  - Filter tasks by status
- **Draft Persistence**: Auto-save task creation forms so your progress isn't lost
- **Visual Indicators**: 
  - Blocked tasks appear greyed out until the blocking task is completed
  - Overdue tasks are highlighted in red
  - Status badges with color coding
- **Responsive Loading**: 2-second simulated delay on create/update with non-blocking UI and loading indicators
- **Task Dependencies**: A task can be blocked by another task until that task is marked as "Done"

### UI/UX Features
- Modern Material Design interface
- Real-time search with instant filtering
- Intuitive status management with dropdown selectors
- Clear visual distinction for blocked and overdue tasks
- Smooth animations and transitions
- Error handling with user-friendly messages

## Architecture

### Backend (Django)
```
backend/
├── backend/              # Project settings
│   ├── settings.py      # Django configuration (CORS, DRF, Database)
│   ├── urls.py          # Main URL router
│   ├── wsgi.py          # WSGI server configuration
│   └── asgi.py          # ASGI server configuration
├── tasks/               # Main app
│   ├── models.py        # Task model with self-referencing relationship
│   ├── views.py         # ViewSet with search and filter endpoints
│   ├── serializers.py   # Task serializer with nested details
│   ├── admin.py         # Django admin registration
│   └── tests.py         # Unit tests
├── manage.py            # Django management script
└── requirements.txt     # Python dependencies
```

**Key Technologies**:
- **Django 6.0**: Web framework
- **Django REST Framework**: REST API
- **django-cors-headers**: CORS support for Flutter
- **SQLite**: Default database (can upgrade to PostgreSQL)

### Frontend (Flutter)
```
frontend/
├── lib/
│   ├── main.dart        # App entry point
│   ├── models/
│   │   └── task.dart    # Task data model
│   ├── services/
│   │   ├── task_api_service.dart      # API client
│   │   └── draft_storage_service.dart # Local storage
│   ├── screens/
│   │   ├── task_list_screen.dart      # Main task list
│   │   └── task_form_screen.dart      # Create/edit form
│   └── widgets/
│       ├── task_card.dart             # Reusable task card
│       └── loading_widget.dart        # Loading indicator
└── pubspec.yaml         # Dart dependencies
```

**Key Technologies**:
- **Flutter 3.10+**: Mobile UI framework
- **http**: HTTP client for API requests
- **shared_preferences**: Local storage for drafts
- **intl**: Date formatting
- **table_calendar**: Calendar widget (extensible for future features)

## Setup Instructions

### Prerequisites
- **Backend**: Python 3.8+, pip
- **Frontend**: Flutter 3.10+, Dart
- **Database**: SQLite (included) or PostgreSQL

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Create a virtual environment** (recommended):
   ```bash
   python -m venv venv
   
   # Windows
   venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Run database migrations**:
   ```bash
   python manage.py migrate
   ```

5. **Create a superuser** (optional, for Django admin):
   ```bash
   python manage.py createsuperuser
   ```

6. **Start the development server**:
   ```bash
   python manage.py runserver
   ```
   
   The API will be available at: `http://localhost:8000/api/tasks/`

### Frontend Setup

1. **Navigate to frontend directory**:
   ```bash
   cd frontend
   ```

2. **Get Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Update the API base URL** (if needed):
   - Open `lib/services/task_api_service.dart`
   - Update `baseUrl` if your backend is running on a different address:
     - For emulator: `http://10.0.2.2:8000/api` (Android)
     - For device: Use your machine's IP address (e.g., `http://192.168.1.5:8000/api`)
     - For local testing: `http://localhost:8000/api`

4. **Run the Flutter app**:
   ```bash
   # For Android emulator
   flutter run
   
   # For iOS simulator
   flutter run -d macos
   
   # For specific device
   flutter run -d [device_id]
   ```

## API Endpoints

All endpoints are prefixed with `/api/`

### Tasks Endpoints
- **GET** `/tasks/` - List all tasks with optional filters
  - Query params: `search=<query>`, `status=<status>`
  - Example: `/tasks/?search=urgent&status=TO_DO`
  
- **POST** `/tasks/` - Create a new task
  - Body: `{ "title": "...", "description": "...", "due_date": "YYYY-MM-DD", "status": "TO_DO", "blocked_by": null }`
  
- **GET** `/tasks/{id}/` - Get a single task
  
- **PUT** `/tasks/{id}/` - Update a task
  
- **DELETE** `/tasks/{id}/` - Delete a task

### Status Values
- `TO_DO` - Not started
- `IN_PROGRESS` - Currently being worked on
- `DONE` - Completed

## Usage Guide

### Creating a Task
1. Tap the **+ (FAB)** button in the bottom right
2. Enter task details:
   - **Title**: Required, what the task is about
   - **Description**: Optional, more details
   - **Due Date**: Required, when it needs to be done
   - **Status**: What state the task is in
   - **Blocked By**: Optional, select another task that must be done first
3. Tap **"Create Task"**
4. The app will show a loading indicator during the 2-second save delay
5. Your draft is auto-saved as you type

### Editing a Task
1. Tap on a task card or use the **Edit** button
2. Modify any field
3. Tap **"Update Task"**
4. Loading state will appear during save

### Managing Tasks
- **Search**: Use the search bar to filter by title
- **Filter by Status**: Use the dropdown to show only specific status tasks
- **Delete**: Tap the **Delete** button on a task card
- **Blocked Tasks**: Greyed out tasks with a lock icon are waiting for another task to finish

### Draft Auto-Save
- When creating a new task, all typed text is auto-saved to local storage
- If you minimize the app or navigate away, your draft is retained
- The draft is cleared after successful task creation

## Development

### Project Structure
- **Separation of Concerns**: Models, Services, Screens, and Widgets are organized separately
- **Reusable Components**: TaskCard widget is modular and reusable
- **Error Handling**: Try-catch blocks with user-friendly error messages
- **State Management**: Simple setState pattern for state management
- **Local Storage**: SharedPreferences for draft persistence

### Adding Features

#### Add a New API Endpoint
1. Create a new method in `tasks/views.py` using `@action` decorator
2. Add the serializer logic if needed
3. Create a corresponding method in `lib/services/task_api_service.dart`
4. Call from the UI screen

#### Add Search/Filter Enhancement
1. Modify `TaskViewSet.get_queryset()` in `backend/tasks/views.py`
2. Update the query parameters in `lib/services/task_api_service.dart`
3. Add UI controls in `lib/screens/task_list_screen.dart`

#### Implement Recurring Tasks (Stretch Goal)
1. Add `recurring` and `recurring_type` fields to Task model
2. Create a management command to generate recurring task copies
3. Add UI toggle in task form
4. Call the endpoint after marking task as Done

## Testing

### Manual Testing
1. Create multiple tasks with different statuses
2. Test the "Blocked By" dependency
3. Verify draft persistence by:
   - Creating a task form
   - Typing content
   - Closing the app
   - Reopening and navigating to create
   - Verify content is still there
4. Test search with various queries
5. Test status filtering

### API Testing
Use curl or Postman to test endpoints:
```bash
# Create a task
curl -X POST http://localhost:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Task", "description": "Test", "due_date": "2024-12-31", "status": "TO_DO"}'

# Get all tasks
curl http://localhost:8000/api/tasks/

# Search tasks
curl http://localhost:8000/api/tasks/?search=urgent

# Filter by status
curl http://localhost:8000/api/tasks/?status=IN_PROGRESS
```

## Database

### Models
The app uses a single primary model:

**Task**
```python
- id (AutoField, PK)
- title (CharField, max_length=200)
- description (TextField, blank=True)
- due_date (DateField)
- status (CharField: TO_DO, IN_PROGRESS, DONE)
- blocked_by (ForeignKey to Task, self-referencing, nullable)
- recurring (CharField: NONE, DAILY, WEEKLY, MONTHLY)
- is_recurring_instance (BooleanField, default=False)
- recurring_parent (ForeignKey to Task, self-referencing, nullable)
- position (IntegerField, default=0)
- created_at (DateTimeField, auto_now_add=True)
- updated_at (DateTimeField, auto_now=True)
```

**Meta Options**:
- `ordering = ['position', '-created_at']` - Tasks ordered by position first, then by creation date descending

### Migrations
All migrations are automatically handled by Django. To create new migrations after model changes:
```bash
python manage.py makemigrations
python manage.py migrate
```

## Troubleshooting

### Backend Issues

**Port Already in Use**
```bash
# Change the port
python manage.py runserver 8001
```

**Database Errors**
```bash
# Reset database
rm db.sqlite3
python manage.py migrate
```

**CORS Errors**
- Ensure `django-cors-headers` is installed
- Check `CORS_ALLOWED_ORIGINS` in `settings.py`
- The app is configured for `localhost:3000`, `localhost:8080`, and machine IP

### Frontend Issues

**Connection Refused**
- Ensure backend is running on `http://localhost:8000`
- If using Android emulator, use `http://10.0.2.2:8000`
- For physical device, use machine IP (e.g., `http://192.168.1.5:8000`)

**Dependencies Not Found**
```bash
flutter pub get
flutter pub upgrade
```

**Hot Reload Not Working**
```bash
flutter clean
flutter pub get
flutter run
```

## Performance Considerations

1. **API Caching**: Responses are refreshed on each request (can add caching layer)
2. **Pagination**: DRF pagination is configured for 100 items per page
3. **Database Indexing**: Consider adding indexes on `title`, `status`, `due_date` for large datasets
4. **Offline Support**: Can enhance with local SQLite caching

## Future Enhancements (Stretch Goals)

- ✓ Debounced autocomplete search with text highlighting
- ✓ Recurring tasks logic (Daily, Weekly, Monthly)
- ✓ Persistent drag-and-drop reordering
- Push notifications for due dates
- Dark mode support
- Task categories/tags
- Collaborative features (sharing tasks)
- Advanced analytics dashboard
- Mobile platform-specific optimizations

## Code Quality

- **Clean Code**: Clear naming conventions, modular functions
- **Error Handling**: Comprehensive try-catch with user feedback
- **Comments**: Key sections documented
- **Stateless Design**: Services are stateless and reusable

## License

This project is part of the Flodo AI Take-Home Assignment.

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review the API documentation
3. Check backend logs: `python manage.py runserver`
4. Check Flutter logs: `flutter logs`

---

**Happy Task Managing with Flodo! 🎯**
