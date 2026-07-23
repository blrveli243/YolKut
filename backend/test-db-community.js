const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const users = await prisma.user.findMany({ take: 1 });
    console.log('Users OK:', users.length);
    const posts = await prisma.post.findMany({ take: 1 });
    console.log('Posts OK:', posts.length);
  } catch (e) {
    console.error('DB Error:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
