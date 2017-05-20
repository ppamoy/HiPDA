//
//  LoginViewModel.swift
//  HiPDA
//
//  Created by leizh007 on 16/9/4.
//  Copyright © 2016年 HiPDA. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Curry

/// 登录的ViewModel
struct LoginViewModel {
    /// 安全问题数组
    static let questions = [
        "安全问题",
        "母亲的名字",
        "爷爷的名字",
        "父亲出生的城市",
        "您其中一位老师的名字",
        "您个人计算机的型号",
        "您最喜欢的餐馆名称",
        "驾驶执照的最后四位数字"
    ]
    
    /// 登录按钮是否可点
    let loginEnabled: Driver<Bool>
    
    /// 是否登录成功
    let loggedIn: Driver<LoginResult>
    
    init(username: Driver<String>, password: Driver<String>, questionid: Driver<Int>, answer: Driver<String>, loginTaps: Driver<Void>) {
        loginEnabled = Driver.combineLatest(username, password, questionid, answer) { (username, password, questionid, answer) in
            username.characters.count > 0 &&
            password.characters.count > 0 &&
            (questionid == 0 || answer.characters.count > 0)
        }
        
        let accountInfos = Driver.combineLatest(username, password, questionid, answer) { ($0, $1, $2, $3) }
        
        loggedIn = loginTaps.withLatestFrom(accountInfos)
            .map { Account(name: $0, uid: 0, questionid: $2, answer: $3, password: $1.md5) } // 这里传密码和密码md5加密后的都能登录成功...
            .flatMapLatest { account in
                return LoginViewModel.login(with: account)
                    .asDriver(onErrorJustReturn: .failure(.unKnown("未知错误")))
        }
    }
    
    /// 登录
    ///
    /// - parameter account: 待登录的账户
    ///
    /// - returns: 返回Observable包含登录结果
    static func login(with account: Account) -> Observable<LoginResult> {
        CookieManager.shared.clear()
        if let cookies = CookieManager.shared.cookies(for: account) {
            CookieManager.shared.set(cookies: cookies, for: account)
            return Observable.just(LoginResult.success(account))
        }
        return Observable.create { observer in
            HiPDAProvider.request(.login(account))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                .mapGBKString()
                .map {
                    return try HtmlParser.loginResult(of: account.name, from: $0)
                }
                .observeOn(MainScheduler.instance)
                .subscribe { event in
                    switch event {
                    case let .next(uid):
                        observer.onNext(.success(Account.uidLens.set(uid, account)))
                    case let .error(error):
                        observer.onNext(.failure(error is LoginError ? error as! LoginError : .unKnown(error.localizedDescription)))
                    default:
                        break
                    }
                    observer.onCompleted()
            }
        }
    }
}
