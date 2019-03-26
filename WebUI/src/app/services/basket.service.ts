import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Rx';
import { Basket, Movement, Item, Order, Cost, Setting } from '../shared/models';

@Injectable()
export class BasketService {

	public basket: Basket[];

    constructor(private http: HttpClient) {
        this.basket = [];
    }

    get count(): number {
        return this.basket.length > 0
            ? this.basket.map(p => p.basketQuantity).reduce((sum, current) => sum + current)
            : 0;
    }

    get(): Observable<Basket[]> {
        return this.http.get<Basket[]>('/api/ecommerce/basket');
    }

    create(model: Basket): Observable<Basket> {
        return this.http.post<Basket>('/api/ecommerce/basket', model);
    }

    update(id: number, model: Basket): Observable<Basket> {
        return this.http.put<Basket>('/api/ecommerce/basket/' + id, model);
    }

    delete(id: number): Observable<any> {
        return this.http.delete<any>('/api/ecommerce/basket/' + id);
    }

    getSetting(): Observable<Setting> {
        return this.http.get<Setting>('/api/ecommerce/setting');
    }

    getPayments(): Observable<Item[]> {
        return this.http.get<Item[]>('/api/ecommerce/payment');
    }

    getShippings(): Observable<Item[]> {
        return this.http.get<Item[]>('/api/ecommerce/shipping');
    }

    getShippingCost(id: string): Observable<Cost> {
        return this.http.get<Cost>('/api/ecommerce/shipping/' + id + '/cost');
    }

    commit(order: Order): Observable<Movement> {
        return this.http.post<Movement>('/api/ecommerce/order', order);
    }
}
