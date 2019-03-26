import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Rx';
import { Login, Token } from '../shared/models';

@Injectable()
export class SessionService {

    constructor(
        private router: Router,
        private http: HttpClient) {
    }

    login(account: Login): Observable<Token> {
        return this.http.post<Token>('/api/login', account);
    }

    logout() {
        const body = { token: localStorage.getItem('token') };
        this.http.post<any>('/api/logout', body).subscribe(result => result);
        this.removeCredentials();
    }

    register(account: Login): Observable<Token> {
        return this.http.post<Token>('/api/register', account);
    }

    grantCredentials(data: any) {
        window.parent.postMessage('token:' + data.token, '*');

        localStorage.setItem('uniqueID', data.uniqueID);
        localStorage.setItem('token', data.token);
        localStorage.setItem('role', data.role);

        const origin = localStorage.getItem('origin');
        this.router.navigate([origin ? origin : 'basket']);
        localStorage.removeItem('origin');
    }

    removeCredentials() {
        window.parent.postMessage('token:', '*');

        localStorage.removeItem('origin');
        localStorage.removeItem('uniqueID');
        localStorage.removeItem('token');
        localStorage.removeItem('role');
        this.router.navigate(['login']);
    }

    get isAuthenticated(): boolean {
        return localStorage.getItem('token') != null && localStorage.getItem('role') === 'Registry';
    }

    checkCredentials(): boolean {
        if (!this.isAuthenticated) {
            this.removeCredentials();
            return false;
        }
        return true;
    }

    getCredentials(): Observable<any>  {
        return this.http.get<any>('/api/authenticated');
    }
}
