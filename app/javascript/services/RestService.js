import http from 'superagent'

export default class RestService {
    constructor(modelPath, baseUrl = '/api/v1/') {
        this.baseUrl = baseUrl
        this.modelPath = modelPath
        this.http = http
    }

    list() {
        let url = this.baseUrl + this.modelPath + '.json?t=' + Date.now()
        return this.executeGet(url)
    }


    get(id) {
        let url = this.baseUrl + this.modelPath + '/' + id + '.json?t=' + Date.now()
        return this.executeGet(url)
    }

    executeGet(url) {
        let httpRequest = http.get(url)
            .set('X-CSRF-Token', Rails.csrfToken())

        return new Promise((resolve, reject) => {
            httpRequest.end((error, response) => {
                if (response.status === 200) {
                    const data = JSON.parse(response.text)
                    resolve(data)
                } else if (response.status === 204) {
                    resolve()
                } else {
                    reject(JSON.parse(response.text))
                }
            })
        });
    }

    executeEmptyPost(url) {
        return new Promise((resolve, reject) => {
            http.post(url)
                .set('X-CSRF-Token', Rails.csrfToken())
                .set('Accept', 'application/json')
                .end((error, response) => {
                    if (response.status === 200 || response.status === 201) {
                        resolve(JSON.parse(response.text))
                    } else {
                        reject(JSON.parse(response.text))
                    }
                })
        })
    }

    executePost(url, data) {
        return new Promise((resolve, reject) => {
            http.post(url)
                .send(data)
                .set('X-CSRF-Token', Rails.csrfToken())
                .set('Accept', 'application/json')
                .end((error, response) => {
                    if (response.status === 200 || response.status === 201) {
                        resolve(JSON.parse(response.text))
                    } else {
                        reject(JSON.parse(response.text))
                    }
                })
        })
    }

    executePut(url, data) {
        return new Promise((resolve, reject) => {
            http.put(url)
                .send(data)
                .set('X-CSRF-Token', Rails.csrfToken())
                .set('Accept', 'application/json')
                .end((error, response) => {
                    if (response.status === 200 || response.status === 201) {
                        resolve(JSON.parse(response.text))
                    } else {
                        reject(JSON.parse(response.text))
                    }
                })
        })
    }

    create(model, multipart) {
        if (multipart) {
            model = this.convertToMultipart(model)
        }

        let url = this.baseUrl + this.modelPath + '.json?t=' + Date.now()

        return new Promise((resolve, reject) => {
            http.post(url)
                .send(model)
                .set('X-CSRF-Token', Rails.csrfToken())
                .set('Accept', 'application/json')
                .end((error, response) => {

                    if (response.status === 200 || response.status === 201) {
                        resolve(JSON.parse(response.text))
                    } else {
                        reject(JSON.parse(response.text))
                    }
                })
        })
    }

    update(id, model, multipart) {
        if (multipart) {
            model = this.convertToMultipart(model)
        }

        let url = this.baseUrl + this.modelPath + '/' + id + '.json?t=' + Date.now()
        return new Promise((resolve, reject) => {
            http.put(url)
                .send(model)
                .set('X-CSRF-Token', Rails.csrfToken())
                .set('Accept', 'application/json')
                .end((error, response) => {
                    if (response.status === 200) {
                        resolve(JSON.parse(response.text))
                    } else {
                        reject(JSON.parse(response.text))
                    }
                })
        })
    }

    remove(id) {
        let url = this.baseUrl + this.modelPath + '/' + id + '.json?t=' + Date.now()
        return new Promise((resolve, reject) => {
            http.delete(url)
                .set('X-CSRF-Token', Rails.csrfToken())
                .set('Accept', 'application/json')
                .end(function (error, response) {
                    if (response.status === 200 || response.status === 204) {
                        response.status === 204 ? resolve() : resolve(JSON.parse(response.text))
                    } else {
                        reject(response.statusText)
                    }
                })
        })
    }

    convertToMultipart(data) {
        let formData = new FormData()
        let modelName = Object.keys(data)[0]
        let fieldNames = Object.keys(data[modelName])

        for (let i = 0; i < fieldNames.length; i++) {
            let fieldName = fieldNames[i]

            if (data[modelName][fieldName]) {

                if (Array.isArray(data[modelName][fieldName])) {
                    Array.from(data[modelName][fieldName]).forEach(file => {
                        formData.append(`${modelName}[${fieldName}][]`, file)
                    })
                } else {
                    formData.append(`${modelName}[${fieldName}]`, data[modelName][fieldName])
                }
            }
        }

        return formData
    }
}
