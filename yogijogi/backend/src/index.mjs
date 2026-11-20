import {
  DynamoDBClient, GetItemCommand, PutItemCommand, ScanCommand, UpdateItemCommand,
} from '@aws-sdk/client-dynamodb';
import { createHandler } from './api.mjs';

const client = new DynamoDBClient({});
const TableName = process.env.REPORTS_TABLE;

// The first report schema contains only string attributes.
function encode(item) {
  return Object.fromEntries(Object.entries(item).map(([key, value]) => [key, { S: value }]));
}

function decode(item) {
  return item && Object.fromEntries(Object.entries(item).map(([key, value]) => [key, value.S]));
}

const store = {
  async list() {
    const { Items = [] } = await client.send(new ScanCommand({ TableName, Limit: 50 }));
    return Items.map(decode).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  },
  async get(id) {
    const { Item } = await client.send(new GetItemCommand({
      TableName, Key: encode({ id }), ConsistentRead: true,
    }));
    return decode(Item);
  },
  async create(item) {
    await client.send(new PutItemCommand({
      TableName, Item: encode(item), ConditionExpression: 'attribute_not_exists(id)',
    }));
  },
  async update(id, fields) {
    const keys = Object.keys(fields);
    const names = Object.fromEntries(keys.map((key) => [`#${key}`, key]));
    const values = encode(Object.fromEntries(keys.map((key) => [`:${key}`, fields[key]])));
    try {
      const { Attributes } = await client.send(new UpdateItemCommand({
        TableName, Key: encode({ id }), ConditionExpression: 'attribute_exists(id)',
        UpdateExpression: 'SET ' + keys.map((key) => `#${key} = :${key}`).join(', '),
        ExpressionAttributeNames: names,
        ExpressionAttributeValues: values,
        ReturnValues: 'ALL_NEW',
      }));
      return decode(Attributes);
    } catch (error) {
      if (error.name === 'ConditionalCheckFailedException') return null;
      throw error;
    }
  },
};

export const handler = createHandler(store, {
  environment: 'dev',
  reportsEnabled: process.env.ENABLE_DEMO_REPORTS === 'true',
});
