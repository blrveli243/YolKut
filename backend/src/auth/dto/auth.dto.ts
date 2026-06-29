import { IsEmail, IsNotEmpty, MinLength } from 'class-validator';

export class AuthDto {
  @IsEmail({}, { message: 'Geçerli bir e-posta adresi giriniz.' })
  @IsNotEmpty()
  email: string;

  @MinLength(6, { message: 'Şifreniz en az 6 karakter olmalıdır.' })
  @IsNotEmpty()
  password: string;
}
