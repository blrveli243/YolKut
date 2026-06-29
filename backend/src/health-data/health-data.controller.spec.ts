import { Test, TestingModule } from '@nestjs/testing';
import { HealthDataController } from './health-data.controller';
import { HealthDataService } from './health-data.service';

describe('HealthDataController', () => {
  let controller: HealthDataController;

  const mockHealthDataService = {};

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthDataController],
      providers: [
        {
          provide: HealthDataService,
          useValue: mockHealthDataService,
        },
      ],
    }).compile();

    controller = module.get<HealthDataController>(HealthDataController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
