import { IsOptional, IsNumber, IsInt, IsString, Min } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  height?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  weight?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  age?: number;

  @IsOptional()
  @IsString()
  gender?: string;

  @IsOptional()
  @IsString()
  dailyGoal?: string;

  @IsOptional()
  @IsNumber()
  @Min(1)
  activityLevel?: number;

  @IsOptional()
  @IsNumber()
  @Min(30)
  targetWeight?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  targetDays?: number;
}
