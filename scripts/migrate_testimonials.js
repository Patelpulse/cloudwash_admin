import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, serverTimestamp } from 'firebase/firestore';
import axios from 'axios';

const BACKEND_API_URL = 'https://cloudwashapi.onrender.com/api';

const firebaseConfig = {
    apiKey: "AIzaSyDQgMfagJiN16By-sS4fbAM0Kf6omkSRG8",
    authDomain: "cloudwash-6ceb6.firebaseapp.com",
    projectId: "cloudwash-6ceb6",
    storageBucket: "cloudwash-6ceb6.firebasestorage.app",
    messagingSenderId: "864806051234",
    appId: "1:864806051234:web:ce326d49512cc22f8a26fb"
};

async function migrateTestimonials() {
    console.log('🚀 Starting testimonials migration...\n');

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    try {
        // Fetch testimonials from backend
        console.log('📥 Fetching testimonials from MongoDB backend...');
        const response = await axios.get(`${BACKEND_API_URL}/testimonials`);
        const testimonials = response.data;

        console.log(`✅ Found ${testimonials.length} testimonials\n`);

        if (testimonials.length === 0) {
            console.log('⚠️  No testimonials found. Exiting.');
            return;
        }

        // Migrate to Firestore
        console.log('📤 Uploading to Firebase Firestore...');
        let successCount = 0;
        let errorCount = 0;

        for (const testimonial of testimonials) {
            try {
                const testimonialData = {
                    name: testimonial.name || '',
                    message: testimonial.message || '',
                    imageUrl: testimonial.imageUrl || '',
                    rating: testimonial.rating || 5,
                    designation: testimonial.designation || '',
                    isActive: testimonial.isActive !== undefined ? testimonial.isActive : true,
                    mongoId: testimonial._id, // Keep MongoDB reference
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                };

                await addDoc(collection(db, 'testimonials'), testimonialData);
                successCount++;
                console.log(`✅ Migrated: ${testimonial.name || 'Anonymous'}`);
            } catch (error) {
                errorCount++;
                console.log(`❌ Failed: ${testimonial.name || 'Anonymous'} - ${error.message}`);
            }
        }

        console.log('\n📊 Migration Summary:');
        console.log(`   Total: ${testimonials.length}`);
        console.log(`   Success: ${successCount}`);
        console.log(`   Failed: ${errorCount}`);
        console.log('\n🎉 Migration complete!');

    } catch (error) {
        console.error('❌ Migration failed:', error.message);
        if (error.response) {
            console.error('Response:', error.response.data);
        }
    } finally {
        process.exit(0);
    }
}

migrateTestimonials();
