import React from 'react';

import { Button, ButtonProps, Text } from '@react-email/components';

export const GreatMemoriesButton = ({ children, ...props }: ButtonProps) => (
  <Button
    {...props}
    className="border bg-great-memories-primary rounded-full no-underline hover:no-underline text-white hover:text-gray-50 font-bold uppercase"
  >
    <Text className="my-3 mx-8">{children}</Text>
  </Button>
);
