//
//  MoviesAPI.swift
//  MoviesApp
//
//  Created by Nicholas Babo on 11/11/18.
//  Copyright © 2018 Nicholas Babo. All rights reserved.
//

import Foundation
import Keys

struct MoviesAPIConfig {
    fileprivate static let keys = MoviesAppKeys()
    static let apikey = keys.aPIKey
}

enum Result<T> {
    case success(T)
    case error(Error)
}

protocol MoviesService{
    func fetchPopularMovies(query:String?, page:Int?, callback: @escaping  (Result<MovieResponse>) -> Void)
    func fetchGenre(callback: @escaping (Result<[Genre]>) -> Void)
}

class MoviesServiceImplementation: MoviesService{
    
    var baseUrl:String = "https://api.themoviedb.org/3/"
    var isFetchInProgress = false
    
    func fetchPopularMovies(query:String? = nil, page:Int? = nil, callback: @escaping (Result<MovieResponse>) -> Void) {
        
        guard !isFetchInProgress else {
            return
        }
        
        // 2
        isFetchInProgress = true
        
        var request = ""
        
        if let query = query?.replacingOccurrences(of: " ", with: "%20"){
            let queryMoviesRequest = "search/movie?api_key="
            request = baseUrl + queryMoviesRequest + MoviesAPIConfig.apikey + "&query=" + query
            
        }else{
            let popularMoviesRequest = "movie/popular?api_key="
            request = baseUrl + popularMoviesRequest + MoviesAPIConfig.apikey
            
            if let page = page{
                request += "&page=\(page)"
                print(request)
            }
        }
        
        guard let url = URL(string: request) else {return}
        
        let task = URLSession.shared.dataTask(with: url){ data, response, error in
            guard let data = data else{
                return
            }
            
            let jsonDecoder = JSONDecoder()
            
            do{
                let responseObj = try jsonDecoder.decode(MovieResponse.self, from: data)
                DispatchQueue.main.async { [weak self] in
                    self?.isFetchInProgress = false
                    callback(.success(responseObj))
                }
            }catch{
                DispatchQueue.main.async { [weak self] in
                    self?.isFetchInProgress = false
                    callback(.error(error))
                }
                
            }
        }
        task.resume()
    }
    
    func fetchGenre(callback: @escaping (Result<[Genre]>) -> Void){
        let genresRequest = "genre/movie/list?api_key="
        let languageRequest = "&language=en-US"
        let request = self.baseUrl + genresRequest + MoviesAPIConfig.apikey + languageRequest
        
        guard let url = URL(string: request) else {return}
        
        let task = URLSession.shared.dataTask(with: url){ data, response, error in
            guard let data = data else {return}
            
            let jsonDecoder = JSONDecoder()
            
            do{
                let responseObj = try jsonDecoder.decode(GenreResponse.self, from: data)
                DispatchQueue.main.async {
                    callback(.success(responseObj.genres))
                }
            }catch{
                callback(.error(error))
            }
        }
        task.resume()
    }
}
