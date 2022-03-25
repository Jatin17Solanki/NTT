## Potential Use Cases

#### Gaming
- Reputation points in an online game
- Skills of character in a game

#### Certification - For a course, participating workshop/hackathon/event
- Proof of attendance of an event
- Badges awarded to users on task completion/competition(Eg skill badges in hackerrank)
- Issue certificates for courses

#### Claims / Skill badges
- Something like what happens on linkedin wherein a user claims that his connection is good at xyz
- letter or recommendation
- shoutouts

#### Community Contribution
- Reward people with NTTs who build for the community. These NTT can be seen as a badge of honor/reputation representing his/her contribution to a commuinty. Such NTTs could be helpful in DAO governance

#### Other
- Token as membership proof
- One time ticketing service (a scenario where you dont want the tickets to be sold further hence non transferable)

---

## Features

### Core
- NTTs cannot be bought.
- NTTs cannot be transferred after mint.
- NTTs can be burned by their current holders.
- NTTs can be burned by their issuers.


### Additional
- Find a mechanism for tokens to be put at stake - however if lost they become burned instead of transferred.
  - I expect that this will have to do with the NTT registry implementation rather than the NTT standard
  - The use case we are targeting are putting "reputation" at risk type of dynamics.


>**NOTE:** A Badge Token standard will have an interface that answers the following questions:
>- can it only be minted by the authority (contract owner)?
>- can it be transferred to another address?
>- has the authority’s permission to transfer to a given address?
>IMO, by having an interface which replies to these questions, we can achieve a lot of different use cases, while being easily understandable.

---

## List of NTT based dapps for reference

- https://mintkudos.xyz/
- https://poap.xyz/
- https://www.lvlprotocol.xyz/

---

## Resources

- https://github.com/ethereum/EIPs/issues/1238
- https://github.com/violetprotocol/ERC1238-token/blob/main/contracts/ERC1238/IERC1238.sol
- https://github.com/violetprotocol/ERC1238-token/blob/main/contracts/ERC1238/ERC1238.sol
- [Level protocol whitepaper](https://docs.google.com/document/d/1mv4vfrYRBwc8nI7jGBoqDITV-desH_UhFNA3UW8dUnw/edit)


---
