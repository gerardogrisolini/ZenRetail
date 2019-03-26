import { Pipe, PipeTransform } from '@angular/core';
import { DatePipe } from '@angular/common';
import { Translation } from 'app/shared/models';

@Pipe({
  name: 'mytranslate'
})
export class MyTranslatePipe implements PipeTransform {
  transform(value: Translation[], args0?: string): string {
    const country = navigator.language.substring(0, 2).toUpperCase();
    const translate = value.find(p => p.country === country);
    return translate != null ? translate.value : args0;
  }
}
