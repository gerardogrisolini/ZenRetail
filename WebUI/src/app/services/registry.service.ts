import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Rx';
import { Registry, Movement, MovementArticle } from '../shared/models';

@Injectable()
export class RegistryService {

    constructor(private http: HttpClient) {
    }

    getById(id: number): Observable<Registry> {
        return this.http.get<Registry>('/api/ecommerce/registry');
    }

    update(id: number, model: Registry): Observable<Registry> {
        return this.http.put<Registry>('/api/ecommerce/registry', model);
    }

    delete(id: number): Observable<any> {
        return this.http.delete<any>('/api/ecommerce/registry');
    }

    getOrders(): Observable<Movement[]> {
        return this.http.get<Movement[]>('/api/ecommerce/order');
    }

    getOrderById(id: number): Observable<Movement> {
        return this.http.get<Movement>('/api/ecommerce/order/' + id);
    }

    getItemsById(id: number): Observable<MovementArticle[]> {
        return this.http.get<MovementArticle[]>('/api/ecommerce/order/' + id + '/items');
    }
}
