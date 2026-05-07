import { db } from './admin/src/lib/firebase';
import { collection, addDoc, serverTimestamp, setDoc, doc } from 'firebase/firestore';

async function simulateCheckIn() {
  const today = new Date().toISOString().split('T')[0];
  const now = new Date().toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });

  // Simulate Ahmad Fauzi (Assuming ID matches the one in DB)
  const attendanceRef = collection(db, 'attendance');
  const recordId = `ahmad_fauzi_${today}`;
  
  console.log('Simulating Check-In for Ahmad Fauzi...');
  
  await setDoc(doc(db, 'attendance', recordId), {
    userId: 'Uu9xT7JmRNcZ2V1XyYwZ', // ID Ahmad Fauzi
    userName: 'Ahmad Fauzi',
    department: 'Rider Delivery',
    date: today,
    checkIn: now,
    status: 'present',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp()
  });

  console.log('Check-In Successful!');
}

simulateCheckIn();
