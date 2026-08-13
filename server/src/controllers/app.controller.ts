import { Controller, Get, Header } from '@nestjs/common';
import { ApiExcludeEndpoint } from '@nestjs/swagger';
import { SystemConfigService } from 'src/services/system-config.service';

@Controller()
export class AppController {
  constructor(private service: SystemConfigService) {}

  @ApiExcludeEndpoint()
  @Get('.well-known/immich')
  getLegacyWellKnown() {
    return this.getWellKnown();
  }

  @ApiExcludeEndpoint()
  @Get('.well-known/great-memories')
  getGreatMemoriesWellKnown() {
    return this.getWellKnown();
  }

  private getWellKnown() {
    return {
      api: {
        endpoint: '/api',
      },
    };
  }

  @ApiExcludeEndpoint()
  @Get('custom.css')
  @Header('Content-Type', 'text/css')
  getCustomCss() {
    return this.service.getCustomCss();
  }
}