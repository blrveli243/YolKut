import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
  console.log('Connecting to database...');
  for (let i = 0; i < 5; i++) {
    try {
      await prisma.$connect();
      console.log('Connected!');
      await prisma.user.deleteMany();
      console.log('All users deleted.');
      break;
    } catch (e) {
      console.log('Retry ' + i + '...');
      await new Promise(r => setTimeout(r, 2000));
    }
  }
  await prisma.$disconnect();
}
main().catch(console.error);
