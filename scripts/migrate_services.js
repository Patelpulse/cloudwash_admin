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

async function migrateServices() {
    console.log('🚀 Starting services migration...\n');

    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    try {
        // Fetch services from backend
        console.log('📥 Fetching services from MongoDB backend...');
        const response = await axios.get(`${BACKEND_API_URL}/services`);
        const services = response.data;

        console.log(`✅ Found ${services.length} services\n`);

        if (services.length === 0) {
            console.log('⚠️  No services found. Exiting.');
            return;
        }

        // Migrate to Firestore
        console.log('📤 Uploading to Firebase Firestore...');
        let successCount = 0;
        let errorCount = 0;

        for (const service of services) {
            try {
                const serviceData = {
                    name: service.name || '',
                    subCategoryId: service.subCategoryId || '',
                    categoryId: service.categoryId || '',
                    price: service.price || 0,
                    description: service.description || '',
                    imageUrl: service.imageUrl || '',
                    isActive: service.isActive !== undefined ? service.isActive : true,
                    unit: service.unit || 'piece',
                    mongoId: service._id, // Keep MongoDB reference
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                };

                await addDoc(collection(db, 'services'), serviceData);
                successCount++;
                console.log(`✅ Migrated: ${service.name}`);
            } catch (error) {
                errorCount++;
                console.log(`❌ Failed: ${service.name} - ${error.message}`);
            }
        }

        console.log('\n📊 Migration Summary:');
        console.log(`   Total: ${services.length}`);
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

migrateServices();
