const admin = require('firebase-admin');
const serviceAccount = require('./user-database-5a0c0-firebase-adminsdk-fbsvc-fcd34ed8ff.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addSampleProducts() {
  const productsRef = db.collection('products');

  const products = [
    {
      product_ID: 'P0001',
      product_Name: 'WATER Free Solution',
      product_Price: 20.0,
      product_Upload_: new Date().toISOString(),
      product_Edit_Time: new Date().toISOString(),
      product_Quantity: 10,
      product_Cetogory: ['Beauty', 'Eco-friendly'],
      saller_ID: 'seller001',
      image_ID: ['assets/images/water_free.jpg', 'assets/images/water_free.jpg'],
      product_Description: 'A revolutionary water-free solution for your beauty needs. Eco-friendly and effective.',
      degree_of_Newness: 4
    },
    {
      product_ID: 'P0002',
      product_Name: 'WATER Not Free Solution',
      product_Price: 40.0,
      product_Upload_: new Date().toISOString(),
      product_Edit_Time: new Date().toISOString(),
      product_Quantity: 15,
      product_Cetogory: ['Health', 'Beauty'],
      saller_ID: 'seller002',
      image_ID: ['assets/images/water_not_free.jpg'],
      product_Description: 'Premium water-based solution for optimal health benefits.',
      degree_of_Newness: 2
    },
    {
      product_ID: 'P0003',
      product_Name: 'CryBaby Doll 10',
      product_Price: 20.0,
      product_Upload_: new Date().toISOString(),
      product_Edit_Time: new Date().toISOString(),
      product_Quantity: 5,
      product_Cetogory: ['Toys', 'Collectibles'],
      saller_ID: 'seller003',
      image_ID: ['assets/images/crybaby.jpg', 'assets/images/crybaby.jpg', 'assets/images/crybaby.jpg'],
      product_Description: 'The latest CryBaby doll with enhanced features and accessories.',
      degree_of_Newness: 3
    },
    {
      product_ID: 'P0004',
      product_Name: 'JoyCon NS【含清修的】',
      product_Price: 140.0,
      product_Upload_: new Date().toISOString(),
      product_Edit_Time: new Date().toISOString(),
      product_Quantity: 2,
      product_Cetogory: ['Gaming', 'Accessories'],
      saller_ID: 'seller004',
      image_ID: ['assets/images/joycon.jpg', 'assets/images/jacket.jpg'],
      product_Description: 'Refurbished Nintendo Switch JoyCon controllers, fully tested and cleaned.',
      degree_of_Newness: 4
    }
  ];

  for (const product of products) {
    const docRef = await productsRef.add(product);
    console.log(`✅ Added product: ${product.product_Name} with ID: ${docRef.id}`);
  }
}

addSampleProducts()
  .then(() => {
    console.log('🎉 Sample data added successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('❌ Error adding sample data:', error);
    process.exit(1);
  });
