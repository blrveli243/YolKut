import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { PrismaService } from './prisma/prisma.service';
import { ValidationPipe } from '@nestjs/common';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import * as bcrypt from 'bcrypt';

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

  const prismaService = app.get(PrismaService);
  const hashedPassword = await bcrypt.hash('password', 10);

  // Ensure default user exists for demonstration
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

  await app.listen(3001, '0.0.0.0');
}
bootstrap();
