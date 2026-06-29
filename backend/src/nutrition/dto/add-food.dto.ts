import {
  IsString,
  IsNotEmpty,
  IsNumber,
  Min,
  IsDateString,
} from 'class-validator';

export class AddFoodDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsNumber()
  @Min(0)
  calories: number;

  @IsNumber()
  @Min(0)
  protein: number;

  @IsNumber()
  @Min(0)
  carbs: number;

  @IsNumber()
  @Min(0)
  fat: number;

  @IsNumber()
  @Min(0)
  sugar: number;

  @IsDateString()
  date: string;
}
