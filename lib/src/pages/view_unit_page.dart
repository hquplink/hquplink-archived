import 'package:flutter/material.dart';
import 'package:hquplink/models.dart';
import 'package:hquplink/services.dart';
import 'package:hquplink/widgets.dart';

/// Renders, and optionally, provides edits for a specific [ArmyUnit].
class ViewUnitPage extends StatefulWidget {
  /// Unit to be rendered.
  final ArmyUnit unit;

  /// Invoked when [unit] is updated. A value of `null` signifies deletion.
  final void Function(ArmyUnit) onUpdate;

  const ViewUnitPage({
    @required this.unit,
    this.onUpdate,
  }) : assert(unit != null);

  @override
  createState() => _ViewUnitState();
}

class _ViewUnitState extends State<ViewUnitPage> {
  @override
  build(context) {
    final catalog = getCatalog(context);
    final details = catalog.lookupUnit(widget.unit.unit);
    final isVehicle = const [
      UnitType.groundVehicle,
      UnitType.repulsorVehicle,
    ].contains(details.type);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        backgroundColor: Color.lerp(
          factionColor(details.faction),
          Colors.white,
          0.25,
        ),
        foregroundColor: Colors.white,
        onPressed: () {},
      ),
      body: CustomScrollView(
        slivers: [
          FactionSliverHeader<void>(
            faction: details.faction,
            title: details.name,
            onMenuPressed: (_) {},
            bottom: _ViewUnitHeader(
              unit: widget.unit,
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Card(
                      child: _ViewUnitCard(
                        title: const Text('Details'),
                        subtitle: Row(
                          children: [
                            details.subTitle != null
                                ? Text('${details.subTitle}, ')
                                : const Text(''),
                            Text(toTitleCase(details.type.name)),
                          ],
                        ),
                        trailing: UnitAvatar(details),
                        body: _SimpleGrid(
                          data: {
                            'Points': Text('${details.points}'),
                            'Miniatures': Text('${details.miniatures}'),
                            'Wounds': Text('${details.wounds}'),
                            isVehicle ? 'Resilence' : 'Courage': Text(
                              '${(isVehicle ? details.resilience : details.courage) ?? '-'}',
                            ),
                            'Speed': Text('${details.speed}'),
                            'Defense': _buildDefenseValue(details),
                            'Attack': _buildAttackValue(details),
                          },
                          oddColor: factionColor(details.faction),
                        ),
                      ),
                    ),
                    Card(
                      child: _ViewUnitCard(
                        title: const Text('Keywords'),
                        body: _ViewUnitKeywords(unit: widget.unit),
                      ),
                    ),
                    Card(
                      child: _ViewUnitCard(
                        title: const Text('Upgrades'),
                        body: _ViewUnitUpgrades(
                          unit: widget.unit,
                        ),
                      ),
                    ),
                    Card(
                      child: _ViewUnitCard(
                        title: const Text('Weapons'),
                        body: _ViewUnitWeapons(
                          unit: widget.unit,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAttackValue(Unit details) {
    if (details.attackSurge == null) {
      return const Text('-');
    }
    final isCrit = details.attackSurge == AttackSurge.critical;
    return AttackSideIcon(
      isCrit ? AttackDiceSide.criticalHit : AttackDiceSide.hit,
      height: 12,
      color: Colors.white,
    );
  }
}

Widget _buildDefenseValue(Unit details) {
  final children = <Widget>[
    SizedBox(
      width: 12,
      height: 12,
      child: DefenseDiceIcon(details.defense),
    ),
  ];
  if (details.hasDefenseSurge) {
    children.add(
      const Padding(
        padding: const EdgeInsets.only(left: 8),
        child: const DefenseSideIcon(
          DefenseDiceSide.surge,
          height: 16,
          color: Colors.white,
        ),
      ),
    );
  }
  return Row(children: children);
}

class _ViewUnitHeader extends StatelessWidget {
  final ArmyUnit unit;

  const _ViewUnitHeader({@required this.unit});

  @override
  build(context) {
    final catalog = getCatalog(context);
    final details = catalog.lookupUnit(unit.unit);
    final sumPoints = catalog.sumUnitPoints(unit);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Row(
        children: [
          Row(
            children: [
              RankIcon(
                rank: details.rank,
                height: 12,
              ),
              Text(' ${toTitleCase(details.rank.name)}'),
            ],
          ),
          Row(
            children: [
              Text('$sumPoints Points'),
            ],
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }
}

class _ViewUnitCard extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final Widget leading;
  final Widget trailing;
  final Widget body;

  const _ViewUnitCard({
    @required this.title,
    @required this.body,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  @override
  build(context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          title: DefaultTextStyle(
            style: theme.textTheme.title,
            child: title,
          ),
          leading: leading,
          subtitle: subtitle,
          trailing: trailing,
        ),
        Padding(
          child: body,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}

class _SimpleGrid extends StatelessWidget {
  final Map<String, Widget> data;
  final Color oddColor;

  const _SimpleGrid({
    this.data,
    this.oddColor,
  });

  @override
  build(context) {
    final theme = Theme.of(context);
    final c = data.entries;
    final results = mapIndexed<Widget, MapEntry<String, Widget>>(c, (i, e) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: i.isOdd ? null : oddColor ?? theme.primaryColor,
        child: Column(
          children: [
            Row(
              children: [
                Text(e.key),
                e.value,
              ],
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            )
          ],
        ),
      );
    }).toList();
    return Column(
      children: results,
    );
  }
}

class _ViewUnitKeywords extends StatelessWidget {
  final ArmyUnit unit;

  const _ViewUnitKeywords({
    @required this.unit,
  });

  @override
  build(context) {
    final keywords = getCatalog(context).lookupUnit(unit.unit).keywords;
    return ListView(
      padding: const EdgeInsets.all(0),
      primary: false,
      shrinkWrap: true,
      children: ListTile.divideTiles(
        context: context,
        tiles: keywords.entries.map(
          (e) {
            // TODO: Fix formatting.
            var text = formatKeyword(e.key).replaceAll('-', ' ');
            if (e.value != null) {
              text += ' ${e.value}';
            }
            return ListTile(
              title: Text(text),
              subtitle: Text(e.key.description),
              // TODO: Add icon(s) for keywords.
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            );
          },
        ),
      ).toList(),
    );
  }
}

class _ViewUnitUpgrades extends StatelessWidget {
  final ArmyUnit unit;

  const _ViewUnitUpgrades({
    @required this.unit,
  });

  @override
  build(context) {
    final catalog = getCatalog(context);
    return ListView(
      primary: false,
      shrinkWrap: true,
      padding: const EdgeInsets.all(0),
      children: unit.upgrades.map(catalog.lookupUpgrade).map((upgrade) {
        return ListTile(
          contentPadding: const EdgeInsets.all(0),
          leading: UpgradeAvatar(upgrade),
          title: Text(upgrade.name),
          subtitle: Text(
            '${toTitleCase(upgrade.type.name)}, ${upgrade.points} Points',
          ),
          // TODO: Add navigation for details of the upgrade.
          // And/or consider a points box here like previous page.
          trailing: const IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: null,
          ),
          // TODO: Add exhaustible icon.
        );
      }).toList(),
    );
  }
}

class _ViewUnitWeapons extends StatelessWidget {
  final ArmyUnit unit;

  const _ViewUnitWeapons({
    @required this.unit,
  });

  @override
  build(context) {
    final catalog = getCatalog(context);
    final details = catalog.lookupUnit(unit.unit);
    final upgrades = unit.upgrades
        .map(catalog.lookupUpgrade)
        .map((u) => u.weapon)
        .where((w) => w != null);
    final weapons = details.weapons.toList()..addAll(upgrades);
    final theme = Theme.of(context);
    return Column(
      children: weapons.map((weapon) {
        final dice = <Widget>[];
        weapon.dice.forEach((type, amount) {
          for (var i = 0; i < amount; i++) {
            dice.add(Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 10,
                height: 10,
                child: AttackDiceIcon(type),
              ),
            ));
          }
        });
        final content = [
          Text(
            weapon.name,
            style: theme.primaryTextTheme.subhead,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: dice,
            ),
          ),
        ];
        if (weapon.keywords.isNotEmpty) {
          content.add(
            Text(
              weapon.keywords.entries.map((e) {
                // TODO: Fix formatting.
                var text = formatKeyword(e.key).replaceAll('-', ' ');
                if (e.value != null) {
                  text += ' ${e.value}';
                }
                return text;
              }).join(', '),
            ),
          );
        }
        // TODO: Make press-able to be able to simulate an attack.
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            // TODO: Add dividers and/or make easier to read.
            children: content,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        );
      }).toList(),
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}