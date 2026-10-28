"""Export code/UI message sources into TTPlayerRes with stable string IDs.

This is a maintenance step. Neither project's standalone build needs its sibling.
"""
import argparse
import json
from pathlib import Path
from sync_catalogs import read_po

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--template', type=Path, default=Path(__file__).resolve().parents[1]/'i18n/ttplayer.pot')
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[2]/'ttpres/resources/extended/messages.json')
    args = parser.parse_args()
    stored = json.loads(args.output.read_text(encoding='utf-8')) if args.output.exists() else {}
    existing = stored.get('messages', [])
    previous = {(x['context'], x['source'], x.get('plural', '')): x for x in existing}
    ident = max(stored.get('next_id', 48000),max([47999] + [x.get(field, 0) for x in existing for field in ('id', 'plural_id')]) + 1)
    messages = []
    for entry in read_po(args.template):
        if entry.obsolete or entry.context.startswith(('ttpres/', 'exe/')): continue
        item = previous.get(entry.key)
        if item is None:
            item = dict(context=entry.context, source=entry.source, id=ident);ident += 1
            if entry.plural:
                item.update(plural=entry.plural, plural_id=ident);ident += 1
        messages.append(item)
    if ident > 60000: raise ValueError('Interface message ID range exhausted')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(dict(schema=1, next_id=ident, messages=messages), ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(f'{len(messages)} interface messages -> {args.output}')

if __name__ == '__main__': main()
