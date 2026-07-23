import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { PrismaService } from './prisma/prisma.service';
import { ValidationPipe } from '@nestjs/common';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS so Flutter app can connect
  app.enableCors();

  // Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Global Exception Filter
  app.useGlobalFilters(new HttpExceptionFilter());

  // Seed default user only in development
  if (process.env.NODE_ENV !== 'production') {
    const prismaService = app.get(PrismaService);
    const bcrypt = await import('bcrypt');
    const hashedPassword = await bcrypt.hash('password', 10);

    await prismaService.user.upsert({
      where: { email: 'test@example.com' },
      update: {
        password: hashedPassword,
      },
      create: {
        email: 'test@example.com',
        password: hashedPassword,
      },
    });
  }

  const port = process.env.PORT || 3001;
  await app.listen(port, '0.0.0.0');
}
bootstrap();

