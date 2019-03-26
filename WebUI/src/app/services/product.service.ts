import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Rx';
import {
    Product, ProductCategory, Category, ProductAttribute,
    ProductAttributeValue, Article, ArticleForm, Brand
} from '../shared/models';

@Injectable()
export class ProductService {
    constructor(private http: HttpClient) {
    }

    getBrands(): Observable<Brand[]> {
        return this.http.get<Brand[]>('/api/ecommerce/brand');
    }

    getFeatured(): Observable<Product[]> {
        return this.http.get<Product[]>('/api/ecommerce/featured');
    }

    getNews(): Observable<Product[]> {
        return this.http.get<Product[]>('/api/ecommerce/new');
    }

    getCategories(): Observable<Category[]> {
        return this.http.get<Category[]>('/api/ecommerce/category');
    }

    getByBrandName(name: string): Observable<Product[]> {
        const url = '/api/ecommerce/brand/' + name;
        return this.http.get<Product[]>(url);
    }

    getByCategoryName(name: string): Observable<Product[]> {
        const url = '/api/ecommerce/category/' + name;
        return this.http.get<Product[]>(url);
    }

    getByProductName(name: string): Observable<Product> {
        const url = '/api/ecommerce/product/' + name;
        return this.http.get<Product>(url);
    }
}
