# Patient Realtime Integration

**Phase:** Task 21 — Patient Realtime Integration  
**Project:** EasyCheck Online

## Integration Points

### Patient Home Screen
- Reads active clinics from `clinics` collection (where isActive == true)
- Displays clinic name, doctor, address, availability
- Shows live parcha count from `queue_sessions` collection
- Shows clinic online/offline status from `clinics` collection

### Patient Clinic Details Screen
- Reads clinic details from `clinics/{clinicId}`
- Reads current queue session from `queue_sessions/{clinicId}_{today}`
- Shows real-time parcha count with stream listener
- Shows clinic online/offline status

## Stream Management

- All Firestore streams are properly disposed when widget is disposed
- No memory leaks from orphaned listeners
- Loading states shown while data is fetching
- Error states shown on Firestore errors

## No Fake Data

- All clinic data comes from Firestore
- No hardcoded clinic records
- No simulated parcha numbers
- Empty state shown when no clinics are available
