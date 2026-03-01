import { db } from './index.js';
import { users, licensePlates, messages, replies, reports, deviceTokens } from './schema.js';
import bcrypt from 'bcryptjs';

async function seed() {
  console.log('Seeding database...');

  const passwordHash = await bcrypt.hash('password123', 12);
  const demoPasswordHash = await bcrypt.hash('Demo1234!', 12);

  // Clean existing seed data (order matters for foreign keys)
  await db.delete(deviceTokens);
  await db.delete(reports);
  await db.delete(replies);
  await db.delete(messages);
  await db.delete(licensePlates);
  await db.delete(users);

  // Create users
  const [demo, alice, bob, charlie] = await db
    .insert(users)
    .values([
      { email: 'demo@carpostall.com', passwordHash: demoPasswordHash, displayName: 'Demo User' },
      { email: 'alice@example.com', passwordHash, displayName: 'Alice' },
      { email: 'bob@example.com', passwordHash, displayName: 'Bob' },
      { email: 'charlie@example.com', passwordHash, displayName: 'Charlie' },
    ])
    .returning();

  console.log('Created users:', demo.id, alice.id, bob.id, charlie.id);

  // Create plates
  const [demoPlate, plate1, plate2, plate3] = await db
    .insert(licensePlates)
    .values([
      { userId: demo.id, plateNumber: 'DEMO123', stateOrRegion: 'CA', claimedAt: new Date() },
      { userId: alice.id, plateNumber: 'ABC1234', stateOrRegion: 'CA', claimedAt: new Date() },
      { userId: bob.id, plateNumber: 'XYZ5678', stateOrRegion: 'NY', claimedAt: new Date() },
      { userId: charlie.id, plateNumber: 'DEF9012', stateOrRegion: 'TX', claimedAt: new Date() },
    ])
    .returning();

  console.log('Created plates:', demoPlate.id, plate1.id, plate2.id, plate3.id);

  // Create sample messages (some TO demo user, some FROM demo user)
  await db.insert(messages).values([
    {
      senderId: alice.id,
      recipientPlateId: demoPlate.id,
      subject: 'Your headlights are on',
      body: 'Hey, just wanted to let you know your headlights are still on in the parking lot!',
    },
    {
      senderId: bob.id,
      recipientPlateId: demoPlate.id,
      subject: 'Nice car!',
      body: 'Love your car! What model is it?',
    },
    {
      senderId: charlie.id,
      recipientPlateId: demoPlate.id,
      body: 'You left your window open in the rain!',
    },
    {
      senderId: demo.id,
      recipientPlateId: plate1.id,
      subject: 'Parking issue',
      body: 'Hi, your car is parked a bit too close to mine. Could you move it a little?',
    },
    {
      senderId: demo.id,
      recipientPlateId: plate2.id,
      body: 'Your tire looks flat, just a heads up!',
    },
    {
      senderId: alice.id,
      recipientPlateId: plate2.id,
      subject: 'Bumper sticker',
      body: 'Love the bumper sticker! Where did you get it?',
    },
  ]);

  console.log('Created sample messages');
  console.log('');
  console.log('=== Test Credentials ===');
  console.log('Demo:    demo@carpostall.com / Demo1234!');
  console.log('Alice:   alice@example.com / password123');
  console.log('Bob:     bob@example.com / password123');
  console.log('Charlie: charlie@example.com / password123');
  console.log('');
  console.log('Seed complete!');
  process.exit(0);
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
