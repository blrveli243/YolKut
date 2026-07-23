import { Controller, Post, Body, Get, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthService } from './auth.service';
import { AuthDto } from './dto/auth.dto';
import { PrismaService } from '../prisma/prisma.service';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly prisma: PrismaService,
  ) {}

  @Post('register')
  register(@Body() dto: AuthDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  login(@Body() dto: AuthDto) {
    return this.authService.login(dto);
  }

  @UseGuards(JwtAuthGuard)
  @Get('verify')
  verify(@Request() req: any) {
    return { valid: true, userId: req.user.sub };
  }

  @Get('wipe-db')
  async wipeDb() {
    await this.prisma.user.deleteMany({});
    return { success: true, message: 'All users wiped!' };
  }
}
