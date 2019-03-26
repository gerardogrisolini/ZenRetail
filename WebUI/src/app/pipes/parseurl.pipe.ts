import { Pipe, PipeTransform } from '@angular/core';
import { environment } from 'environments/environment';
import { Media } from 'app/shared/models';

@Pipe({
  name: 'parseUrl'
})
export class ParseUrlPipe implements PipeTransform {
  transform(value: Media[], args0?: string): string {
    let path = '/media/';
    if (args0 !== null && args0 === 'thumb') {
      path = '/thumb/';
    }
    return value.length > 0 ? path + value[0].name : '';
  }
}
