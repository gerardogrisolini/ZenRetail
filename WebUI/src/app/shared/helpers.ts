import { Headers } from '@angular/http';

export class Helpers {

    static currency = 'EUR';
    static utc = 'UTC';

    static distinct(a: any[]): any[] {
        const seen: any = {};
        const out: any[] = [];
        const len = a.length;
        let j = 0;
        for (let i = 0; i < len; i++) {
            const item = a[i];
            if (seen[item.label] !== 1) {
                seen[item.label] = 1;
                out[j++] = item;
            }
        }
        return out;
    }

    static getHeaders(): Headers {
        const headers = new Headers();
        headers.append('Authorization', `Bearer ${localStorage.getItem('token')}`);
        headers.append('Content-Type', 'application/json');
        // headers.append('Access-Control-Allow-Origin', '*');
        return headers;
    }
}
