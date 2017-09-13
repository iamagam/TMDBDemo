//
//  ViewController.swift
//  TMDBDemo
//
//  Created by Agam on 13/09/17.
//  Copyright © 2017 Agam. All rights reserved.
//

import UIKit
import Foundation

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    func loadImageUsingCache(withUrl url : URL) {
        //let url = URL(string: urlString)
        self.image = nil
        
        // check cached image
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        // if not, download image from url
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if error != nil {
                print(error!)
                return
            }
            
            DispatchQueue.main.async {
                if let image = UIImage(data: data!) {
                    imageCache.setObject(image, forKey: url.absoluteString as NSString)
                    self.image = image
                }
            }
            
        }).resume()
    }
}



class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
    @IBOutlet weak var tableView: UITableView!
    var refreshControl: UIRefreshControl!
    
    var sectionHeaderTitles: NSArray!
    
    var moviesArray = [Any]()
    
    var newMoviePage = 1
    var popularMoviePage = 1
    var topRatedMoviePage = 1
    
    var newMovieTotalRecord = 0
    var popularMovieTotalRecord = 0
    var topRatedMovieTotalRecord = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Movies"
        
        self.sectionHeaderTitles = ["New in Theaters", "Popular", "Highest Rated This Year"]
         
        for _ in 0..<sectionHeaderTitles.count
        {
            moviesArray.append(NSArray())
        }
        
        self.tableView.tableFooterView = UIView()
        self.tableView.delaysContentTouches = false
        
        activityIndicator.frame = self.view.frame
        activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.3)
        activityIndicator.hidesWhenStopped = true;
        activityIndicator.center = self.view.center;
        self.view.addSubview(activityIndicator)
        self.view.bringSubview(toFront: activityIndicator)
        activityIndicator.isHidden = true
        activityIndicator.isUserInteractionEnabled = true
        
        tableView.register(UINib(nibName: "MovieStoreCell", bundle: nil), forCellReuseIdentifier: "MovieStoreCell")
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        
        self.getNewMovies()
        self.getPopularMovies()
        self.getTopRatedMovies()
    }

    func refresh(sender:AnyObject) {
        refreshControl.endRefreshing()
         newMoviePage = 1
         popularMoviePage = 1
         topRatedMoviePage = 1
        
         newMovieTotalRecord = 0
         popularMovieTotalRecord = 0
         topRatedMovieTotalRecord = 0
        
        self.getNewMovies()
        self.getPopularMovies()
        self.getTopRatedMovies()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //MARK: UITableView Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaderTitles.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        let array = moviesArray[section] as! NSArray
        return array.count > 0 ? 30 : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let array = moviesArray[section] as! NSArray
        let header = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 30))
        header.backgroundColor = UIColor.white
        
        let seperator = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: (section == 0 ? 0 : 5)))
        seperator.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        header.addSubview(seperator)
        
        let label = UILabel(frame: CGRect(x: 15, y: 10, width: header.bounds.width - 40, height: 20))
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.text = array.count > 0 ? sectionHeaderTitles[section] as? String : ""
        header.addSubview(label)
        return header
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let array = moviesArray[section] as! NSArray
        return array.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieStoreCell", for: indexPath) as! MovieStoreCell
        cell.collectionView.tag = 100 + indexPath.section
        cell.collectionView.delegate = self
        cell.collectionView.dataSource = self
        cell.collectionView.reloadData()
        return cell
    }
    
    
    //MARK: UICollectionView Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let array = moviesArray[collectionView.tag - 100] as? NSArray
        return (array?.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomMovieViewCell", for: indexPath) as! CustomMovieViewCell
        let array = moviesArray[collectionView.tag - 100] as? NSArray
        let movieObject = array?[indexPath.row] as? NSDictionary
        cell.titleLabel.text = movieObject?["title"] as? String
        cell.imageView.image = nil
        cell.imageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        if let imagePath = movieObject?["poster_path"] as? String
        {
            let imageURl = "https://image.tmdb.org/t/p/w500" + imagePath
            self.downloadImage(url: URL(string: imageURl)!, imageView: cell.imageView)
        }
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let width = 300 //(view.frame.size.width - 15)
        return CGSize(width: width, height: 250)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let array = moviesArray[collectionView.tag - 100] as? NSArray
        if indexPath.row == (array?.count)! - 1 && (array?.count)! != 0
        {
            switch collectionView.tag {
            case 100:
                if (array?.count)! < newMovieTotalRecord
                {
                    self.getNewMovies()
                }
                break
            case 101:
                if (array?.count)! < popularMovieTotalRecord
                {
                    self.getPopularMovies()
                }
                break
            case 102:
                if (array?.count)! < topRatedMovieTotalRecord
                {
                    self.getTopRatedMovies()
                }
                break
            default:
                break
            }
        }
        
    }
    
    
    //MARK: Image Loading
    func downloadImage(url: URL, imageView : UIImageView) {
        print("Download Started")
        
        imageView.loadImageUsingCache(withUrl: url)
        
    }
    
    
    
    //MARK: Animator
    func startSystemIndicator()
    {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.activityIndicator.isHidden = false
        }
    }
    
    func stopSystemIndicator()
    {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    //MARK: TMDB APIs
    func getNewMovies()
    {
        stopSystemIndicator()
        startSystemIndicator()
        let postData = NSData(data: "{}".data(using: String.Encoding.utf8)!)
        
        let previousMonth = Date().getPreviousMonth()
        let currentDate = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let preMonthStr = formatter.string(from: previousMonth!)
        let todayStr = formatter.string(from: currentDate)
        
        let urlStr = "https://api.themoviedb.org/3/discover/movie?include_video=false&include_adult=false&region=us&language=en-US&api_key=1fb5a75f87e3ed061b94c6f53a9c7ed7" + ("&page=\(String(newMoviePage))") + ("&primary_release_date.lte=\(todayStr)&primary_release_date.gte=\(preMonthStr)")
        
        let request = NSMutableURLRequest(url: NSURL(string: urlStr)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.httpBody = postData as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if self.newMoviePage == 1
            {
                self.moviesArray[0] = NSArray()
            }
            self.perform(#selector(self.stopSystemIndicator), with: nil, afterDelay: 0.1)
            self.stopSystemIndicator()
            if (error != nil) {
                //print(error ?? "Error nil")
            } else {
                //                let httpResponse = response as? HTTPURLResponse
                //                print(httpResponse ?? "Data Nil")
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:Any]
                    let posts = json["results"] as? [[String: Any]] ?? []
                    //print("getNewMovies : \(posts)")
                    
                    //total_pages
                    if posts.count > 0
                    {
                        //self.moviesArray.append(posts)
                        self.newMoviePage += 1
                    }
                    let array = self.moviesArray[0] as! NSArray
                    let mutableArray = NSMutableArray(array: array)
                    mutableArray.addObjects(from: posts)
                    self.moviesArray[0] = mutableArray
                    
                    self.newMovieTotalRecord = (json["total_results"] as? Int)!
                    self.stopSystemIndicator()
                    self.tableView.reloadData()
                } catch let error as NSError {
                    print(error)
                }
            }
            self.stopSystemIndicator()
            self.tableView.reloadData()
        })
        
        dataTask.resume()
    }
    
    func getPopularMovies()
    {
        stopSystemIndicator()
        startSystemIndicator()
        let postData = NSData(data: "{}".data(using: String.Encoding.utf8)!)
        let urlStr = "https://api.themoviedb.org/3/movie/popular?region=us&language=en-US&api_key=1fb5a75f87e3ed061b94c6f53a9c7ed7" + ("&page=\(String(popularMoviePage))")
        let request = NSMutableURLRequest(url: NSURL(string: urlStr)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.httpBody = postData as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            if self.popularMoviePage == 1
            {
                self.moviesArray[1] = NSArray()
            }
            self.perform(#selector(self.stopSystemIndicator), with: nil, afterDelay: 0.1)
            self.stopSystemIndicator()
            if (error != nil) {
                //print(error ?? "Error nil")
            } else {
                //                let httpResponse = response as? HTTPURLResponse
                //                print(httpResponse ?? "Data Nil")
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:Any]
                    let posts = json["results"] as? [[String: Any]] ?? []
                    //print("getPopularMovies : \(posts)")
                    if posts.count > 0
                    {
                        //self.moviesArray.append(posts)
                        self.popularMoviePage += 1
                    }
                    let array = self.moviesArray[1] as! NSArray
                    let mutableArray = NSMutableArray(array: array)
                    mutableArray.addObjects(from: posts)
                    self.moviesArray[1] = mutableArray
                    
                    self.popularMovieTotalRecord = (json["total_results"] as? Int)!
                    self.stopSystemIndicator()
                    self.tableView.reloadData()
                } catch let error as NSError {
                    print(error)
                }
            }
            self.tableView.reloadData()
            self.stopSystemIndicator()
        })
        
        dataTask.resume()
    }
    
    func getTopRatedMovies()
    {
        stopSystemIndicator()
        startSystemIndicator()
        let postData = NSData(data: "{}".data(using: String.Encoding.utf8)!)
        
        let currentDate = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let currentYear = formatter.string(from: currentDate)
        
        let urlStr = "https://api.themoviedb.org/3/discover/movie?vote_count.gte=500&include_video=false&include_adult=false&sort_by=vote_average.desc&region=us&language=en-US&api_key=1fb5a75f87e3ed061b94c6f53a9c7ed7" + ("&page=\(String(topRatedMoviePage))") + ("&primary_release_year=\(currentYear)")
        let request = NSMutableURLRequest(url: NSURL(string: urlStr)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.httpBody = postData as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            if self.topRatedMoviePage == 1
            {
                self.moviesArray[2] = NSArray()
            }
            self.perform(#selector(self.stopSystemIndicator), with: nil, afterDelay: 0.1)
            self.stopSystemIndicator()
            if (error != nil) {
                //print(error ?? "Error nil")
            } else {
                //                let httpResponse = response as? HTTPURLResponse
                //                print(httpResponse ?? "Data Nil")
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:Any]
                    let posts = json["results"] as? [[String: Any]] ?? []
                    //print("getTopRatedMovies : \(posts)")
                    if posts.count > 0
                    {
                        //self.moviesArray.append(posts)
                        self.topRatedMoviePage += 1
                    }
                    let array = self.moviesArray[2] as! NSArray
                    let mutableArray = NSMutableArray(array: array)
                    mutableArray.addObjects(from: posts)
                    self.moviesArray[2] = mutableArray
                    
                    self.topRatedMovieTotalRecord = (json["total_results"] as? Int)!
                    
                    self.tableView.reloadData()
                } catch let error as NSError {
                    print(error)
                }
            }
            self.tableView.reloadData()
            self.stopSystemIndicator()
        })
        
        dataTask.resume()
    }
}

