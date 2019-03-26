import { Pipe, PipeTransform } from '@angular/core';
import { Product } from 'app/shared/models';

@Pipe({
  name: 'articleInfo'
})
export class ArticleInfoPipe implements PipeTransform {
  transform(value: Product, args0?: string, args1?: boolean): string {
    if (value == null || value.productId === 0) {
      return '';
    }
    if (args0 == null) {
      return value.productName;
    }
    const barcode = args0;
    let info = args1 ? '' : value.productName;
    const ids = value.articles
                     .find(p => p.barcodes.find(e => e.barcode === barcode) != null)
                     .attributeValues.map(p => p.attributeValueId);

    value.attributes.map(p => p.attributeValues.forEach(b => {
        if (ids.indexOf(b.attributeValue.attributeValueId) > -1) {
          info += ` ${b.attributeValue.attributeValueName}`;
        }
    }));

    return info;
    }
  }
