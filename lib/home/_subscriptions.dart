import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wogan/models/subscription.dart';
import 'package:wogan/models/subscription_model.dart';
import 'package:wogan/show/show_screen.dart';
import 'package:wogan/ui/image.dart';

class HomeSubscriptionsScreen extends StatelessWidget {
  const HomeSubscriptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionModel>(
      builder: (context, model, child) => FutureBuilder<List<Subscription>>(
        future: model.listSubscriptions(),
        builder: (context, snapshot) {
          var error = snapshot.error;
          if (error != null) {
            log('Oops', error: error, stackTrace: snapshot.stackTrace);
          }

          var subscriptions = snapshot.data;
          if (subscriptions == null) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              var subscription = subscriptions[index];

              return SubscriptionListTile(subscription: subscription);
            },
          );
        },
      ),
    );
  }
}

class SubscriptionListTile extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionListTile({Key? key, required this.subscription}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var model = context.read<SubscriptionModel>();

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShowScreen(id: subscription.id))),
      child: Container(
        margin: EdgeInsets.only(bottom: 16, left: 8, right: 8),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: 16),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedImage(
                        uri: subscription.imageUrl.replaceAll('{recipe}', '400x400'),
                        width: 128
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(8),
                    child: CachedImage(
                        uri: subscription.network.logoUrl.replaceAll('{type}', 'colour').replaceAll('{size}', '450').replaceAll('{format}', 'png'),
                        width: 32
                    ),
                  )
                ],
              ),
            ),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 4),
                  child: Text(subscription.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 4),
                  child: Text(subscription.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  child: _SubscribeButton(
                    subscription: subscription,
                    onSubscribe: () async {
                      await model.saveSubscription(subscription);
                    },
                    onUnsubscribe: () async {
                      await model.deleteSubscription(subscription.id);
                    },
                  ),
                )
              ],
            )),
          ],
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final Subscription subscription;
  final Function() onSubscribe;
  final Function() onUnsubscribe;

  const _SubscribeButton({Key? key, required this.subscription, required this.onSubscribe, required this.onUnsubscribe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (subscription.subscribedAt == null) {
      return ElevatedButton(onPressed: () => onSubscribe(), child: Text('Subscribe'));
    }

    return ElevatedButton(onPressed: () => onUnsubscribe(), child: Text('Unsubscribe'));
  }
}

