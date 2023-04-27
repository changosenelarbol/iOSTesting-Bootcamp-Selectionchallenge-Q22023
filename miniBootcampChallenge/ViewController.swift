//
//  ViewController.swift
//  miniBootcampChallenge
//

import UIKit

class ViewController: UICollectionViewController {
    
    private struct Constants {
        static let title = "Mini Bootcamp Challenge"
        static let cellID = "imageCell"
        static let cellSpacing: CGFloat = 1
        static let columns: CGFloat = 3
        static var cellSize: CGFloat?
    }
    
    private lazy var urls: [URL] = URLProvider.urls
    private var photos: [UIImage] = [] {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.title
        
        // MARK: - Here you can change between the two functions
         
        //loadPhotosWithoutFreezingUI()
        
        loadAllPhotosFirst()
    }

    private func addLoader() -> UIActivityIndicatorView {
        let loader: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
        loader.isHidden = false
        loader.backgroundColor = .white
        loader.hidesWhenStopped = true
        loader.center = self.view.center
        self.view.addSubview(loader)
        loader.startAnimating()
        return loader
    }
    
    // MARK: - Functions to create loading animation
    private func setUpViewsForAnimation() {
        self.view.backgroundColor = .white
        self.collectionView.alpha = 0
    }
    
    private func startViewsAnimation() {
        UIView.animate(withDuration: 0.75, delay: 0) {
            self.collectionView.alpha = 1
        }
    }

    // MARK: - Functions to load photos
    private func loadAllPhotosFirst() {
        setUpViewsForAnimation()
        let loader = addLoader()
        loadAllImagesFrom(urls: self.urls) { [weak self] result in
            switch result {
            case .success(let photos):
                self?.photos = photos
                loader.stopAnimating()
                self?.startViewsAnimation()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func loadPhotosWithoutFreezingUI() {
        for url in urls {
            getImageFrom(url: url) { result in
                switch result {
                case .success(let image):
                    self.photos.append(image)
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }

}


// TODO: 1.- Implement a function that allows the app downloading the images without freezing the UI or causing it to work unexpected way
func getImageFrom(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
    DispatchQueue.global().async {
        do  {
            let data = try Data(contentsOf: url)
            if let image = UIImage(data: data) {
                completion(.success(image))
            }
        } catch let error {
            completion(.failure(error))
        }
    }
}

// TODO: 2.- Implement a function that allows to fill the collection view only when all photos have been downloaded, adding an animation for waiting the completion of the task.
func loadAllImagesFrom(urls: [URL], completion: @escaping (Result<[UIImage], Error>) -> Void) {
    let dispatchGroup = DispatchGroup()
    var photos: [UIImage] = []
    for url in urls {
        dispatchGroup.enter()
        getImageFrom(url: url) { result in
            switch result {
            case .success(let image):
                photos.append(image)
                dispatchGroup.leave()
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        completion(.success(photos))
    }
}

// MARK: - UICollectionView DataSource, Delegate
extension ViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath) as? ImageCell else { return UICollectionViewCell() }
        let image = self.photos[indexPath.row]
        cell.display(image)
        return cell
    }
}


// MARK: - UICollectionView FlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if Constants.cellSize == nil {
          let layout = collectionViewLayout as! UICollectionViewFlowLayout
            let emptySpace = layout.sectionInset.left + layout.sectionInset.right + (Constants.columns * Constants.cellSpacing - 1)
            Constants.cellSize = (view.frame.size.width - emptySpace) / Constants.columns
        }
        return CGSize(width: Constants.cellSize!, height: Constants.cellSize!)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        Constants.cellSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        Constants.cellSpacing
    }
}
