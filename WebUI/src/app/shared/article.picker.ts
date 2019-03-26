import { Component, OnInit, EventEmitter, Input, Output, ViewEncapsulation } from '@angular/core';
import { Validators, FormControl, FormGroup, FormBuilder } from '@angular/forms';
import { Product } from 'app/shared/models';

@Component({
    moduleId: module.id,
    selector: 'article-picker',
    templateUrl: 'article.picker.html',
    encapsulation: ViewEncapsulation.None
})
export class ArticlePicker implements OnInit {

    dataform: FormGroup;
    @Input('product') product: Product;
    @Output('onPicked') onPicked = new EventEmitter();

    constructor(private fb: FormBuilder) { }

    ngOnInit() {
        const group = {'quantity': ['', [Validators.required]]};
        this.product.attributes.forEach(p => {
          group[p.attribute.attributeName] = ['', [Validators.required]];
        });
        this.dataform = this.fb.group(group);
        this.dataform.controls['quantity'].setValue(1);
    }

    pickerClick() {
        let articles = this.product.articles;
        this.product.attributes.forEach(e => {
          const valueId = this.dataform.controls[e.attribute.attributeName].value;
          articles = articles.filter(p => p.attributeValues.findIndex(a => a.attributeValueId === valueId) > -1)
        });
        this.onPicked.emit(articles[0]);
    }
}
