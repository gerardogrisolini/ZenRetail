import { Injectable } from '@angular/core';
import { HttpRequest, HttpInterceptor, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs/Rx';
import { environment } from 'environments/environment';

@Injectable()
export class UrlInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    if (req.url.indexOf('i18n') < 0) {
      req = req.clone({
        // url: environment.apiUrl + req.url,
        headers: req.headers.set('Authorization', `Bearer ${localStorage.getItem('token')}`)
      });
    }
    req = req.clone({ headers: req.headers.set('Content-Type', 'application/json') });
    req = req.clone({ headers: req.headers.set('Accept', 'application/json') });
    // req = req.clone({ headers: req.headers.set('Access-Control-Allow-Origin', '*') });
    return next.handle(req);
  }
}
